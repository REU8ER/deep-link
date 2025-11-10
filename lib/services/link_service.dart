import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/link_model.dart';

class DeepLink {
  static final DeepLink _instance = DeepLink._internal();
  factory DeepLink() {
    return _instance;
  }
  DeepLink._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  static late String _baseUrl;
  static String? _apiToken;

  /// Cancela a assinatura do stream de links.
  /// Chame este método quando não precisar mais ouvir os links.
  /// Isso é importante para evitar vazamentos de memória.
  /// Exemplo de uso:
  /// ```dart
  /// DeepLink().dispose();
  /// ```
  void dispose() => _sub?.cancel();

  static void init({required String baseUrl, required String apiToken}) {
    if (baseUrl.isEmpty) {
      throw Exception('Base URL não pode ser vazia');
    }
    if (apiToken.isEmpty) {
      throw Exception('API Token não pode ser vazio');
    }

    _baseUrl = baseUrl;
    _apiToken = apiToken;
  }

  void listen(void Function(LinkModel) onLinkData) {
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('Received deep link: $uri');

      try {
        final linkData = await _parseLinkFromUri(uri);
        if (linkData != null) {
          onLinkData(linkData);
        }
      } catch (e) {
        debugPrint('Erro ao processar deep link: $e');
      }
    });
  }

  Future<void> checkInitialLink(void Function(LinkModel) onLinkData) async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      debugPrint('Initial deep link: $initial');

      try {
        final linkData = await _parseLinkFromUri(initial);
        if (linkData != null) {
          onLinkData(linkData);
        }
      } catch (e) {
        debugPrint('Erro ao processar link inicial: $e');
      }
    }
  }

  static Future<LinkModel?> _parseLinkFromUri(Uri uri) async {
    // Caso 1: HTTPS deep link (https://dominio/prefixo/slug)
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return await _parseHttpsLink(uri);
    }

    // Caso 2: Custom scheme (myapp://id ou myapp://link/id)
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return await _parseCustomSchemeLink(uri);
    }

    return null;
  }

  static Future<LinkModel?> _parseHttpsLink(Uri uri) async {
    final dominio = uri.host;
    final segments = uri.pathSegments;

    String prefixo = '';
    String slug = '';

    if (segments.length == 1) {
      slug = segments[0];
    } else if (segments.length >= 2) {
      prefixo = segments[0];
      slug = segments[1];
    }

    if (slug.isEmpty) return null;

    final id = '$dominio~-$prefixo~-$slug';

    try {
      return await DeepLink.getLink(id);
    } catch (e) {
      debugPrint('Erro ao buscar link por ID: $e');
      return null;
    }
  }

  static Future<LinkModel?> _parseCustomSchemeLink(Uri uri) async {
    // Scheme formato: myapp://link/dominio~-prefixo~-slug
    // ou: myapp://dominio~-prefixo~-slug
    // ou: myapp://abrir?id=dominio~-prefixo~-slug&appPath=produto/123

    debugPrint('Parsing custom scheme: ${uri.scheme}://${uri.host}${uri.path}');

    // Opção 1: ID no path (myapp://link/dominio~-prefixo~-slug)
    if (uri.pathSegments.isNotEmpty) {
      final allSegments = uri.pathSegments.join('/');

      // Se o path contém ~-, é um ID
      if (allSegments.contains('~-')) {
        final id = allSegments;
        try {
          return await DeepLink.getLink(id);
        } catch (e) {
          debugPrint('Erro ao buscar link por ID do scheme: $e');
        }
      }
    }

    // Opção 2: ID no host (myapp://dominio~-prefixo~-slug)
    if (uri.host.contains('~-')) {
      final id = uri.host;
      try {
        return await DeepLink.getLink(id);
      } catch (e) {
        debugPrint('Erro ao buscar link por ID no host: $e');
      }
    }

    // Opção 3: Query params (fallback offline)
    // myapp://abrir?id=xxx&appPath=produto/123&titulo=Produto
    if (uri.queryParameters.isNotEmpty) {
      return _createLinkFromQueryParams(uri.queryParameters);
    }

    return null;
  }

  static Future<LinkModel?> _createLinkFromQueryParams(
    Map<String, String> params,
  ) async {
    final id = params['id'];

    if (id != null && id.contains('~-')) {
      final parts = id.split('~-');

      final prefixo = parts.length == 3 ? parts[1] : null;
      final slug = parts.length == 3 ? parts[2] : parts[1];

      if (parts.length >= 2) {
        try {
          return await DeepLink.getLink(id);
        } catch (e) {
          debugPrint('Erro ao buscar link por ID no query: $e');
        }

        return LinkModel(
          id: id,
          dominio: parts[0],
          prefixo: prefixo,
          slug: slug,
          titulo: params['titulo'],
          descricao: params['descricao'],
          appPath: params['appPath'],
          scheme: params['scheme'],
          urlDesktop: params['urlDesktop'],
        );
      }
    }

    return null;
  }

  static Future<LinkModel> createLink(LinkModel link) async {
    if (_apiToken == null || _apiToken!.isEmpty) {
      throw Exception(
        'Token não inicializado. Chame DeepLink.init(baseUrl, apiToken) primeiro.',
      );
    }

    if (link.dominio.isEmpty) {
      throw Exception('Campo obrigatório: dominio');
    }
    if (link.slug.isEmpty) {
      throw Exception('Campo obrigatório: slug');
    }
    if (link.titulo == null || link.titulo!.isEmpty) {
      throw Exception('Campo obrigatório: titulo');
    }

    final url = Uri.parse('$_baseUrl/api/links');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiToken',
      },
      body: jsonEncode(link.toJson()),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return LinkModel.fromMap(json);
    } else if (response.statusCode == 401) {
      throw Exception('Token de autenticação inválido ou expirado');
    } else if (response.statusCode == 403) {
      throw Exception('Permissão negada para criar link neste domínio');
    } else {
      throw Exception('Erro ao criar link: ${response.body}');
    }
  }

  static Future<LinkModel> getLink(String id) async {
    final url = Uri.parse('$_baseUrl/api/links/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return LinkModel.fromMap(json);
    } else if (response.statusCode == 404) {
      throw Exception('Link não encontrado');
    } else {
      throw Exception('Erro ao buscar link: ${response.body}');
    }
  }

  static Future<String> getIdLinkFromUri(Uri uri) async {
    final domain = uri.queryParameters['domain'] ?? uri.host;

    final pathList = uri.pathSegments;
    final path = pathList.length == 1
        ? '~-~-${pathList.first}'
        : uri.path.replaceAll('/', '~-');
    return '$domain$path';
  }

  static Future<Map<String, String>?> getQueryParametersFromUri(Uri uri) async {
    final querys = Map<String, String>.from(uri.queryParameters);
    querys.remove('domain');

    return querys.isEmpty ? null : querys;
  }
}
