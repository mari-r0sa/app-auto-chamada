// screens/config.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_bar.dart';
import '../services/auth_service.dart'; // Importe o AuthService

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  static const secondaryColor = Color(0xFFD9D9D9);

  // Lê o tipo de usuário do SharedPreferences
  String _userType = "carregando"; // Valor inicial

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('user_type') ?? 'Aluno'; 
    });
  }

  void _exportarRelatorioAluno() {
    print("Exportar relatório do aluno");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exportando relatório de presenças...")),
    );
  }

  void _exportarRelatorioHoje() {
    print("Exportar relatório de presenças de hoje");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exportando relatório de hoje...")),
    );
  }

  void _exportarRelatorioOutraData() {
    print("Exportar relatório de outra data");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selecione uma data para exportar...")),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      // ---------- APPBAR (RF005) ----------
      appBar: const CustomAppBar(
        title: "Auto-chamada",
      ),

      // ---------- CORPO DO APP ----------
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          // Mostra os botões corretos (RF017 ou RF018)
          child: _userType == "carregando"
              ? const CircularProgressIndicator()
              : _userType == "Aluno"
                  ? _buildAlunoView() // Botões do Aluno
                  : _buildProfessorView(), // Botões do Professor
        ),
      ),

      // ---------- BARRA INFERIOR ----------
      bottomNavigationBar: CustomBottomBar(
        onLogout: () async {
          AuthService.logout(context); // Chama o serviço de logout
        },
        onHome: () {
           // Navega de volta para a Home
           Navigator.pushReplacementNamed(context, '/home');
        },
        onConfig: () {
          // Já está na Config, não faz nada
        },
      ),
    );
  }


  // --- Widget para os botões do Aluno ---
  Widget _buildAlunoView() {
    return _buildButton(
      text: "Exportar meu relatório de presenças",
      onPressed: _exportarRelatorioAluno,
    );
  }

  // --- Widget para os botões do Professor ---
  Widget _buildProfessorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          text: "Exportar relatório de presenças de hoje",
          onPressed: _exportarRelatorioHoje,
        ),
        const SizedBox(height: 16),
        _buildButton(
          text: "Exportar relatório de outra data",
          onPressed: _exportarRelatorioOutraData,
        ),
      ],
    );
  }

  // --- Widget helper para construir os botões ---
  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}