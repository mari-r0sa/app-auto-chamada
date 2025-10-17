import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_bar.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  static const secondaryColor = Color(0xFFD9D9D9);

  // "Mock" de tipo de usuário para testar enquanto a API não fica pronta
  // "aluno" ou "prof"
  final String userType = "aluno";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      // ---------- APPBAR ----------
      appBar: const CustomAppBar(
        title: "Auto-chamada",
      ),

      // ---------- CORPO DO APP ----------
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0), // Margem lateral
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
          children: [

            // Verifica o tipo de usuário
            if (userType == "aluno") ...[
              // ----------- ALUNO -----------
              SizedBox(
                width: double.infinity, // ocupa 100% da largura disponível
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    print("Exportar relatório do aluno");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Exportando relatório de presenças...")),
                    );
                  },
                  child: const Text(
                    "Exportar meu relatório de presenças",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else if (userType == "prof") ...[
              // ----------- PROFESSOR -----------
              SizedBox(
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
                  onPressed: () {
                    print("Exportar relatório de presenças de hoje");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Exportando relatório de hoje...")),
                    );
                  },
                  child: const Text(
                    "Exportar relatório de presenças de hoje",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16), // Espaço entre botões

              SizedBox(
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
                  onPressed: () {
                    print("Exportar relatório de outra data");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Selecione uma data para exportar...")),
                    );
                  },
                  child: const Text(
                    "Exportar relatório de outra data",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      // ---------- BARRA INFERIOR ----------
      bottomNavigationBar: CustomBottomBar(
        onLogout: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('jwt_token'); // limpa token
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        onHome: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Já está na HomeScreen")),
          );
        },
        onConfig: () {
          Navigator.pushReplacementNamed(context, '/config');
        },
      ),
    );
  }
}