import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_bar.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/csv_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  static const secondaryColor = Color(0xFFD9D9D9);
  String _userType = "carregando";

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeInt = prefs.getInt('user_type') ?? 0;

    setState(() {
      _userType = (typeInt == 1) ? "Aluno" : "Professor";
    });
  } 

  Future<int> _getAlunoId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id") ?? 0;
  }

  Future<void> exportarRelatorioAluno(int alunoId) async {
    try {
      final registros = await ApiService.getRelatorioAluno(alunoId);

      final caminho = await CsvService.gerarCSV(
        List<Map<String, dynamic>>.from(registros),
        "relatorio_aluno_$alunoId",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CSV salvo em:\n$caminho")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void _exportarRelatorioHoje() async {
    try {
      final registros = await ApiService.getRelatorioHoje();

      final caminho = await CsvService.gerarCSV(
        List<Map<String, dynamic>>.from(registros),
        "relatorio_hoje",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CSV salvo em:\n$caminho")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void _exportarRelatorioOutraData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    final data = "${picked.year}-${picked.month}-${picked.day}";

    try {
      final registros = await ApiService.getRelatorioPorData(data);

      final caminho = await CsvService.gerarCSV(
        List<Map<String, dynamic>>.from(registros),
        "relatorio_$data",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("CSV salvo em:\n$caminho")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Auto-chamada"),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: _userType == "carregando"
              ? const CircularProgressIndicator()
              : _userType == 2
                  ? _buildAlunoView()
                  : _buildProfessorView(),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        onLogout: () => AuthService.logout(context),
        onHome: () => Navigator.pushReplacementNamed(context, '/home'),
        onConfig: () {},
      ),
    );
  }

  Widget _buildAlunoView() {
    return _buildButton(
      text: "Exportar meu relatório de presenças",
      onPressed: () async {
        final id = await _getAlunoId();
        exportarRelatorioAluno(id);
      },
    );
  }

  Widget _buildProfessorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(
          text: "Exportar relatório de presenças de hoje",
          onPressed: _exportarRelatorioHoje,
        ),
        const SizedBox(height: 16),
        _buildButton(
          text: "Exportar relatório de outra data",
          onPressed: _exportarRelatorioOutraData,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}