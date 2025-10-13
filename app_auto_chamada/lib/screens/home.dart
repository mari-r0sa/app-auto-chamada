import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _userIconKey = GlobalKey();

  static const primaryColor = Color(0xFF9B1536);
  static const secondaryColor = Color(0xFFD9D9D9);

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
      bottomNavigationBar: BottomAppBar(
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // User Icon
              Builder(
                builder: (context) => GestureDetector(
                  onTapDown: (details) async {
                    final RenderBox overlay =
                        Overlay.of(context)!.context.findRenderObject() as RenderBox;

                    if (_userIconKey.currentContext == null) return;
                    final RenderBox iconBox =
                        _userIconKey.currentContext!.findRenderObject() as RenderBox;
                    final Offset iconPosition = iconBox.localToGlobal(Offset.zero);
                    final Size iconSize = iconBox.size;
                    final Rect iconRect = iconPosition & iconSize;

                    final result = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromRect(
                        iconRect,
                        Offset.zero & overlay.size,
                      ),
                      items: [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Sair', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                      elevation: 8,
                      color: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );

                    if (result == 'logout') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Logout realizado!")),
                      );
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  },
                  child: Container(
                    key: _userIconKey,
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),

              // Home Icon
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  print("Já está na HomeScreen");
                },
              ),

              // Config Icon
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/config');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}