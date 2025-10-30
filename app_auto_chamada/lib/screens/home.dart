import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_bar.dart';
import '../services/api_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const primaryColor = Color(0xFF9B1536);
  static const secondaryColor = Color(0xFFD9D9D9);

  late Future<Map<String, dynamic>> _horariosFuture;

  @override
  void initState() {
    super.initState();
    _horariosFuture = ApiService.getHorarios();
  }

  // --- FUNÇÃO PARA LIDAR COM O REGISTRO DE PRESENÇA ---
  Future<void> _handleRegistrarPresenca(String horaInicio) async {
    
    // PEGAR OS DADOS REAIS DO ALUNO (Salvos no Login)
    final prefs = await SharedPreferences.getInstance();
    final int? alunoId = prefs.getInt('aluno_id'); 

    if (alunoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Aluno não logado. Faça login novamente.'))
      );
      return;
    }

    // DEFINIR AS VALIDAÇÕES
    bool toqueValidado = true;
    bool movimentoValidado = true;

    try {
      //  Buscar o ID da chamada ativa
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buscando chamada para $horaInicio...')),
      );
      final chamadaAtiva = await ApiService.getChamadaAtiva(horaInicio);
      final int idChamada = chamadaAtiva['id_chamada'];
      
      //  Registrar a presença
      final resultado = await ApiService.registrarPresenca(
        alunoId: alunoId,
        idChamada: idChamada,
        validacaoToqueTela: toqueValidado,
        validacaoMovimento: movimentoValidado,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Presença registrada! (Aluno: ${resultado['aluno_id']})')),
      );

    } catch (e) {
      // Erro (Ex: "Nenhuma chamada ativa...", "Chamada expirada.", etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Auto-chamada",
      ),
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

            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _horariosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar horários: ${snapshot.error}'));
                  }
                  if (snapshot.hasData) {
                    final List<dynamic> horarios = snapshot.data?['horarios'] ?? [];
                    if (horarios.isEmpty) {
                      return const Center(child: Text('Nenhum horário configurado.'));
                    }

                    return ListView.builder(
                      itemCount: horarios.length,
                      itemBuilder: (context, index) {
                        final horario = horarios[index]; 

                        final String horaInicioStr = horario['hora_inicio'] ?? '??:??';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
                          child: GestureDetector(
                            onTap: () {
                              print("Horário selecionado: $horaInicioStr");
                              _handleRegistrarPresenca(horaInicioStr); 
                            },
                            child: Card(
                              color: secondaryColor,
                              elevation: 2,
                              child: SizedBox(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    horaInicioStr, 
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('Carregando...'));
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        onLogout: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('jwt_token'); 
          await prefs.remove('aluno_id'); // Limpar o ID do aluno
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