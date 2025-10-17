import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'screens/config.dart';
import 'screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auto-chamada',
      theme: ThemeData(primaryColor: const Color(0xFF9B1536)),
      initialRoute: '/login',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/config': (context) => const ConfigScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
