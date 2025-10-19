import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final Color backgroundColor;
  final VoidCallback? onLogout;
  final VoidCallback? onHome;
  final VoidCallback? onConfig;

  const CustomBottomBar({
    super.key,
    this.backgroundColor = const Color(0xFF9B1536),
    this.onLogout,
    this.onHome,
    this.onConfig,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey userIconKey = GlobalKey();

    return BottomAppBar(
      color: backgroundColor,
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
                      Overlay.of(context).context.findRenderObject() as RenderBox;

                  if (userIconKey.currentContext == null) return;
                  final RenderBox iconBox =
                      userIconKey.currentContext!.findRenderObject() as RenderBox;
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
                    color: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );

                  if (result == 'logout') {
                    if (onLogout != null) {
                      onLogout!();
                    }
                  }
                },
                child: Container(
                  key: userIconKey,
                  padding: const EdgeInsets.all(4.0),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),

            // Home Icon
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: onHome,
            ),

            // Config Icon
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: onConfig,
            ),
          ],
        ),
      ),
    );
  }
}