import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  // Key para obter a posição global do ícone do usuário
  final GlobalKey _userIconKey = GlobalKey();

  static const primaryColor = Color(0xFF9B1536);
  static const secondaryColor = Color(0xFFD9D9D9);

  // "Mock" de tipo de usuário para testar enquanto a API não fica pronta
  // "aluno" ou "prof"
  final String userType = "aluno";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      // ---------- APPBAR ----------
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, // Remove botão de "voltar" padrão
        title: Stack( // Permite colocar logo + título por cima da appbar
          alignment: Alignment.center,
          children: [
            // logo católica
            Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(
                'assets/logo-catolica-sc.svg',
                width: 80,
                height: 40,
              ),
            ),

            // título do app
            const Center(
              child: Text(
                "Auto-chamada",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
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
                      print("Usuário deslogou");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Logout realizado!")),
                      );
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
                  // Importante: usar pushReplacement para não empilhar telas
                  Navigator.pushReplacementNamed(context, '/home');
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