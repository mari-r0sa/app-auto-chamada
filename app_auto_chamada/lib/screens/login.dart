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
                  height: isLoginMode
                      ? MediaQuery.of(context).size.height * 0.6
                      : MediaQuery.of(context).size.height * 0.8,
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
                          const Icon(Icons.person, size: 130, color: primaryColor),
                          const SizedBox(height: 40),

                          // Campo Nome (apenas no cadastro)
                          if (!isLoginMode) ...[
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Nome",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nomeController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: secondaryColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Campo E-mail
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "E-mail",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: secondaryColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Campo Senha
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Senha",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: senhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: secondaryColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),

                          // Campo Confirmar Senha (apenas no cadastro)
                          if (!isLoginMode) ...[
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Confirmar senha",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: confirmarSenhaController,
                              obscureText: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: secondaryColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),

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
                              onPressed: isLoading ? null : () async {
                                setState(() => isLoading = true);

                                if (isLoginMode) {
                                  // LOGIN
                                  try {
                                    final response = await ApiService.login(
                                      emailController.text.trim(),
                                      senhaController.text.trim(),
                                    );

                                    final token = response['token'];

                                    if (token != null) {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('jwt_token', token);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Login realizado com sucesso!"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      Navigator.pushReplacementNamed(context, '/home');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Credenciais inválidas."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Erro ao conectar: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  // CADASTRO
                                  if (senhaController.text != confirmarSenhaController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("As senhas não coincidem."),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    setState(() => isLoading = false);
                                    return;
                                  }

                                  try {
                                    await ApiService.cadastrar(
                                      nomeController.text.trim(),
                                      emailController.text.trim(),
                                      senhaController.text.trim(),
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Cadastro realizado com sucesso!"),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Erro ao cadastrar: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }

                                setState(() => isLoading = false);
                              },
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
                      color: secondaryColor,
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
}