import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/link_model.dart';

class LinkService {
  static String baseUrl =
      'https://us-central1-deep-link-hub.cloudfunctions.net';

  static Future<LinkModel> createLink(LinkModel link, String token) async {
    final url = Uri.parse('$baseUrl/api/links');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(link.toJson()),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return LinkModel.fromJson(json);
    } else {
      throw Exception('Erro ao criar link: ${response.body}');
    }
  }

  static Future<LinkModel> getLink(String slug) async {
    final url = Uri.parse('$baseUrl/api/links/$slug');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return LinkModel.fromJson(json);
    } else if (response.statusCode == 404) {
      throw Exception('Link não encontrado');
    } else {
      throw Exception('Erro ao buscar link: ${response.body}');
    }
  }
}
