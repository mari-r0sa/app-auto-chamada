import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // --- LOGIN  ---
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
    final url = Uri.parse('$baseUrl/usuarios/cadastrar'); 
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

  // --- FUNÇÕES DE CHAMADA ---

  // Busca os horários de configuração (para o home.dart)
  static Future<Map<String, dynamic>> getHorarios() async {
    final url = Uri.parse('$baseUrl/chamadas/configuracao/horarios');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao buscar horários (${response.statusCode})');
    }
  }

  // Busca o ID da chamada ativa para uma string de hora (ex: "19:00")
  static Future<Map<String, dynamic>> getChamadaAtiva(String horaInicio) async {
    final url = Uri.parse('$baseUrl/chamadas/chamadas/ativa/${Uri.encodeComponent(horaInicio)}');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
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
      headers: {
        'Content-Type': 'application/json',
      },
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