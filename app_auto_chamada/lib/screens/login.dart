// screens/login.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/custom_appbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const primaryColor = Color(0xFF9B1536);
  static const secondaryColor = Color(0xFFD9D9D9);

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  bool isLoginMode = true;
  bool isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.login(
        emailController.text.trim(),
        senhaController.text.trim(),
      );

      final token = response['token'];
      final usuario = response['usuario'];

      if (token != null && usuario != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setInt('aluno_id', usuario['id']); 
        await prefs.setString('user_type', usuario['tipo']); 

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login realizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
           Navigator.pushReplacementNamed(context, '/home');
        }
       
      } else {
        _showError("Credenciais inválidas.");
      }
    } catch (e) {
      _showError("Erro ao conectar: $e");
    }
    setState(() => isLoading = false);
  }

  // --- FUNÇÃO DE CADASTRO ---
  Future<void> _handleCadastro() async {
     if (senhaController.text != confirmarSenhaController.text) {
      _showError("As senhas não coincidem.");
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiService.cadastrar(
        nomeController.text.trim(),
        emailController.text.trim(),
        senhaController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cadastro realizado com sucesso! Faça o login."),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        isLoginMode = true;
        nomeController.clear();
        emailController.clear();
        senhaController.clear();
        confirmarSenhaController.clear();
      });
    } catch (e) {
      _showError("Erro ao cadastrar: $e");
    }
    setState(() => isLoading = false);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Auto-chamada"),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  // Altura dinâmica baseada no modo
                  height: isLoginMode
                      ? MediaQuery.of(context).size.height * 0.55
                      : MediaQuery.of(context).size.height * 0.75,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person, size: 100, color: primaryColor),
                          const SizedBox(height: 20),

                          if (!isLoginMode) ...[
                            _buildTextField(nomeController, "Nome"),
                            const SizedBox(height: 16),
                          ],

                          _buildTextField(emailController, "E-mail"),
                          const SizedBox(height: 16),

                          _buildTextField(senhaController, "Senha", isObscure: true),
                          const SizedBox(height: 16),
                          
                          // Campo Confirmar Senha (apenas no cadastro)
                          if (!isLoginMode) ...[
                            _buildTextField(confirmarSenhaController, "Confirmar Senha", isObscure: true),
                            const SizedBox(height: 24),
                          ],
                          
                          if (isLoginMode) const SizedBox(height: 24),

                          // Botão principal
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: isLoading 
                                ? null 
                                : (isLoginMode ? _handleLogin : _handleCadastro), // Chama as funções
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      isLoginMode ? "Entrar" : "Cadastrar-se",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Link alternar login / cadastro
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLoginMode = !isLoginMode;
                      nomeController.clear();
                      emailController.clear();
                      senhaController.clear();
                      confirmarSenhaController.clear();
                    });
                  },
                  child: Text(
                    isLoginMode
                        ? "Ainda não tem conta? Cadastre-se"
                        : "Já tem uma conta? Fazer login",
                    style: const TextStyle(
                      color: Colors.black54, // Corrigido para melhor leitura
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper para construir os campos de texto ---
  Widget _buildTextField(TextEditingController controller, String label, {bool isObscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: secondaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}