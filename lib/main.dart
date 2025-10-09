import 'package:app_automatizar_chamada/screens/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AutoChamadaApp());
}

class AutoChamadaApp extends StatelessWidget {
  const AutoChamadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto-chamada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(), // tela inicial
    );
  }
}
