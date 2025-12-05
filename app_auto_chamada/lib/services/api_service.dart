import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Detecta automaticamente se está rodando em Android/Emulador/Web
  static final String _baseIp =
      defaultTargetPlatform == TargetPlatform.android
          ? "10.0.2.2"
          : "localhost";

  static final String baseUrl = "http://192.168.1.101:3000/api";

  // -------------------------
  // AUTH HEADERS
  // -------------------------
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // -------------------------
  // LOGIN & CADASTRO
  // -------------------------
  static Future<Map<String, dynamic>> login(
      String email, String senha) async {
    final url = Uri.parse("$baseUrl/usuarios/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "senha": senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception("Falha no login: ${body['erro'] ?? response.body}");
  }

  static Future<Map<String, dynamic>> cadastrar(
      String nome, String email, String senha) async {
    final url = Uri.parse("$baseUrl/usuarios/cadastro");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nome": nome,
        "email": email,
        "senha": senha,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(
        "Falha no cadastro: ${body['erro'] ?? response.body}");
  }

  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id") ?? 0;
    // OBS: 0 significa que o usuário não está logado
  }

  // -------------------------
  // CONFIGURAÇÃO DAS CHAMADAS
  // -------------------------
  static Future<Map<String, dynamic>> getHorarios() async {
    final url = Uri.parse("$baseUrl/chamadas/configuracao/horarios");
    final response =
        await http.get(url, headers: await _getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
        "Falha ao buscar horários (${response.statusCode})");
  }

  // -------------------------
  // PRESENÇAS - HOJE
  // -------------------------
  static Future<Map<String, dynamic>> getPresencasHoje(
      int alunoId) async {
    final url =
        Uri.parse("$baseUrl/chamadas/presencas/hoje/$alunoId");

    final response =
        await http.get(url, headers: await _getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
        "Falha ao buscar presenças (${response.statusCode})");
  }

  // -------------------------
  // CHAMADA ATIVA
  // -------------------------
  //
  // IMPORTANTE: aqui estava o maior erro!
  // A rota estava assim:
  //   /chamadas/chamadas/ativa
  // Coloquei a versão correta:
  //   /chamadas/ativa
  //
  static Future<Map<String, dynamic>> getChamadaAtiva(
      String horaInicio) async {
    final hora = Uri.encodeComponent(horaInicio);
    final url = Uri.parse("$baseUrl/chamadas/ativa/$hora");

    final response =
        await http.get(url, headers: await _getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {"erro": "Chamada não encontrada"};

    throw Exception(body["erro"]);
  }

  static Future<Map<String, dynamic>> registrarPresenca({
    required int alunoId,
    required int idChamada,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse("$baseUrl/chamadas/presencas");

    final response = await http.post(
      url,
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        "user_id": alunoId,
        "id_chamada": idChamada,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final body =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception("Falha: ${body['erro'] ?? response.body}");
  }

  // -------------------------
  // RELATÓRIOS
  // -------------------------
  static Future<List<dynamic>> getRelatorioAluno(
      int alunoId) async {
    final url = Uri.parse("$baseUrl/relatorio/aluno/$alunoId");

    final response =
        await http.get(url, headers: await _getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar relatório do aluno");
  }

  static Future<List<dynamic>> getRelatorioHoje() async {
    final url = Uri.parse("$baseUrl/relatorio/hoje");

    final response =
        await http.get(url, headers: await _getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar relatório de hoje");
  }

  static Future<List<dynamic>> getRelatorioPorData(
      String data) async {
    final url = Uri.parse("$baseUrl/relatorio/data/$data");

    final response =
        await http.get(url, headers: await _getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar relatório da data selecionada");
  }
}