import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
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
  static String? _token;
  static late String _baseUrl;

  /// Cancela a assinatura do stream de links.
  /// Chame este método quando não precisar mais ouvir os links.
  /// Isso é importante para evitar vazamentos de memória.
  /// Exemplo de uso:
  /// ```dart
  /// DeepLink().dispose();
  /// ```
  void dispose() => _sub?.cancel();

  /// Chame este método para inicializar o DeepLink com o token e a URL base.
  /// Antes de chamar qualquer outro método do DeepLink, você deve chamar este método.
  /// O token é usado para autenticação nas requisições.
  /// A URL base é usada para construir as URLs das APIs.
  /// Exemplo de uso:
  /// ```dart
  /// await DeepLink.init(
  ///   token: 'seuTokenAqui',
  ///   baseUrl: 'https://seu-servidor.com',
  /// );
  /// ```
  static void init({required String token, required String baseUrl}) {
    if (baseUrl.isEmpty) {
      throw Exception('Base URL não pode ser vazia');
    }
    if (token.isEmpty) {
      throw Exception('Token não pode ser vazio');
    }

    _token = token;
    _baseUrl = baseUrl;
  }

  /// Um stream que emite eventos quando um link é aberto.
  /// Você pode ouvir este stream para receber os dados do link.
  /// Exemplo de uso:
  /// ```dart
  /// DeepLink().listen((linkData) {
  ///   print('Link recebido: ${linkData.slug}');
  /// });
  /// ```
  /// Certifique-se de chamar DeepLink.init(token, urlBase) antes de usar este método.
  void listen(void Function(LinkModel) onLinkData) {
    if (_token == null) {
      throw Exception(
        'Token não inicializado. Chame DeepLink.init(token, urlBase) primeiro.',
      );
    }
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      final slug = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (slug.isNotEmpty) {
        final data = await DeepLink.getLink(slug);
        onLinkData(data);
      }
    });
  }

  /// Verifica se há um link inicial e chama o callback com os dados do link.
  Future<void> checkInitialLink(void Function(LinkModel) onLinkData) async {
    if (_token == null) {
      throw Exception(
        'Token não inicializado. Chame DeepLink.init(token, urlBase) primeiro.',
      );
    }
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      final slug = initial.pathSegments.isNotEmpty
          ? initial.pathSegments.last
          : '';
      if (slug.isNotEmpty) {
        final data = await DeepLink.getLink(slug);
        onLinkData(data);
      }
    }
  }

  /// Cria um novo link com os dados fornecidos.
  static Future<LinkModel> createLink(LinkModel link) async {
    if (_token == null) {
      throw Exception(
        'Token não inicializado. Chame DeepLink.init(token, urlBase) primeiro.',
      );
    }
    final url = Uri.parse('$_baseUrl/api/links');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(link.toJson()),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return LinkModel.fromMap(json);
    } else {
      throw Exception('Erro ao criar link: ${response.body}');
    }
  }

  /// Retorna os dados de um link existente pelo ID (dominio.com=slug).
  /// Se o link não for encontrado, lança uma exceção.
  /// Se o link for encontrado, retorna um objeto LinkModel.
  /// Exemplo de uso:
  /// ```dart
  /// try {
  ///   final link = await DeepLink.getLink('seu_slug_aqui');
  ///   print('Link encontrado: ${link.titulo}');
  /// } catch (e) {
  ///   print('Erro ao buscar link: $e');
  /// }
  /// ```
  static Future<LinkModel> getLink(String id) async {
    if (_token == null) {
      throw Exception(
        'Token não inicializado. Chame DeepLink.init(token, urlBase) primeiro.',
      );
    }
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
}
