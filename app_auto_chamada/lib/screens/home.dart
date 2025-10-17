import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_bar.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const primaryColor = Color(0xFF9B1536);
  static const secondaryColor = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------- APPBAR ----------
      appBar: const CustomAppBar(
        title: "Auto-chamada",
      ),

      // ---------- CORPO ----------
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Card principal
            Card(
              color: primaryColor,
              elevation: 4,
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    "Próxima chamada em: XX min",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de horários de chamadas - Cria um card para cada horário do array
            ...["19:15", "20:00", "20:45", "21:15"].map(
              (horario) => Padding( 
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GestureDetector( 
                  onTap: () { 
                    print("Horário selecionado: $horario"); 
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Card( 
                      color: secondaryColor,
                      elevation: 2,
                      child: SizedBox(
                        height: 60,
                        child: Center(
                          child: Text(
                            horario,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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