import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const primaryColor = Color(0xFF9B1536);
  static const secondaryColor = Color(0xFFD9D9D9);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  bool isLoginMode = true; // controla se está em modo login ou cadastro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------- APPBAR ----------
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        title: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                'assets/logo-catolica-sc.svg',
                width: 60,
                height: 30,
              ),
            ),
            const Center(
              child: Text(
                "Auto-chamada",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),

      // ---------- CORPO ----------
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ----------- CARD DE LOGIN / CADASTRO -----------
                SizedBox(
                  height: isLoginMode
                      ? MediaQuery.of(context).size.height * 0.7
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
                          // Ícone
                          const Icon(
                            Icons.person,
                            size: 130,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 40),

                          // Campo E-mail
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "E-mail",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Campo Senha
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Senha",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                          ),

                          // Campo Confirmar Senha (apenas no modo cadastro)
                          if (!isLoginMode) ...[
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Confirmar senha",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
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
                              onPressed: () {
                                if (isLoginMode) {
                                  print("Fazer login");
                                  Navigator.pushReplacementNamed(
                                      context, '/home');
                                } else {
                                  print("Cadastrar usuário");
                                  // Aqui você poderia validar as senhas e salvar o usuário
                                  if (senhaController.text !=
                                      confirmarSenhaController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("As senhas não coincidem."),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    isLoginMode = true; // volta pro login
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Cadastro realizado!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              child: Text(
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

                // ----------- LINK ALTERNAR LOGIN / CADASTRO -----------
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLoginMode = !isLoginMode;
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