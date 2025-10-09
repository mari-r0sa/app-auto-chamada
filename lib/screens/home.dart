import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const primaryColor = Color(0xFF9B1536);
  static const secondaryColor = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, // evita conflito com o leading padrão
        title: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                'assets/logo-catolica-sc.svg',
                width: 80,
                height: 40,
              ),
            ),
            const Center(
              child: Text(
                "Auto-chamada",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal)
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Card grande - próxima chamada
            Card(
              color: primaryColor,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    "Próxima chamada em: XXmin", // Aqui você pode usar lógica dinâmica depois
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Horários das chamadas
            ...["19:15", "20:00", "20:45", "21:15"].map(
              (horario) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GestureDetector(
                  onTap: () {
                    print("Horário selecionado: $horario");
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0), // <-- padding lateral
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
          
      bottomNavigationBar: BottomAppBar(
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Icon(Icons.person, color: Colors.white),
              Icon(Icons.home, color: Colors.white),
              Icon(Icons.settings, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
