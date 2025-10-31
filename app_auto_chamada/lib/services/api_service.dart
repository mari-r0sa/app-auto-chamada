// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String _baseIp = defaultTargetPlatform == TargetPlatform.android 
      ? '10.0.2.2' 
      : 'localhost';
  static final String baseUrl = 'http://$_baseIp:3000/api';

  // Pega o token salvo e monta os headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Envia o token
    };
  }

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
      final body = jsonDecode(response.body);
      throw Exception('Falha no login: ${body['erro'] ?? response.body}');
    }
  }

  // --- CADASTRO ---
  static Future<Map<String, dynamic>> cadastrar(String nome, String email, String senha) async {
    final url = Uri.parse('$baseUrl/usuarios/cadastro');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception('Falha no cadastro: ${body['erro'] ?? response.body}');
    }
  }

  // Busca os horários de configuração (para o home.dart)
  static Future<Map<String, dynamic>> getHorarios() async {
    final url = Uri.parse('$baseUrl/chamadas/configuracao/horarios');
    final response = await http.get(
      url,
      headers: await _getAuthHeaders(), // Usa token
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao buscar horários (${response.statusCode})');
    }
  }

  // Busca os registros de presença (status) de hoje
  static Future<Map<String, dynamic>> getPresencasHoje(int alunoId) async {
    final url = Uri.parse('$baseUrl/chamadas/presencas/hoje/$alunoId');
    final response = await http.get(
      url,
      headers: await _getAuthHeaders(), // Usa token
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao buscar presenças (${response.statusCode})');
    }
  }


  // Busca o ID da chamada ativa para uma string de hora
  static Future<Map<String, dynamic>> getChamadaAtiva(String horaInicio) async {
    final url = Uri.parse('$baseUrl/chamadas/chamadas/ativa/${Uri.encodeComponent(horaInicio)}');
    final response = await http.get(
      url,
      headers: await _getAuthHeaders(), // Usa token
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception('${body['erro'] ?? 'Chamada não disponível'}');
    }
  }

  // Registra a presença do aluno
  static Future<Map<String, dynamic>> registrarPresenca({
    required int alunoId,
    required int idChamada,
    required bool validacaoToqueTela,
    required bool validacaoMovimento,
  }) async {
    final url = Uri.parse('$baseUrl/chamadas/presencas');
    final response = await http.post(
      url,
      headers: await _getAuthHeaders(), // Usa token
      body: jsonEncode({
        'aluno_id': alunoId,
        'id_chamada': idChamada,
        'validacao_toque_tela': validacaoToqueTela,
        'validacao_movimento': validacaoMovimento,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception('Falha: ${body['erro'] ?? response.body}');
    }
  }
}