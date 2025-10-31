// services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  /**
   * Limpa TODOS os dados do usuário do SharedPreferences e
   * redireciona para a tela de Login.
   */
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Limpa todos os dados salvos no login
    await prefs.remove('jwt_token');
    await prefs.remove('aluno_id');
    await prefs.remove('user_type');

    // Navega para o Login, removendo todas as telas anteriores
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}