import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // --- LOGIN ---
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse('$baseUrl/usuarios/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha no login (${response.statusCode}): ${response.body}');
    }
  }

  // --- CADASTRO ---
  static Future<Map<String, dynamic>> cadastrar(String nome, String email, String senha) async {
    final url = Uri.parse('$baseUrl/usuarios/cadastrar');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha no cadastro (${response.statusCode}): ${response.body}');
    }
  }
}