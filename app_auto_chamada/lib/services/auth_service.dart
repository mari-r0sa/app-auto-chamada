import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token'); // apaga o token salvo

    // Redireciona para tela de login
    Navigator.pushReplacementNamed(context, '/login');
  }
}