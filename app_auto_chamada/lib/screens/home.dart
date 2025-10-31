// screens/home.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Para o Timer

import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_bar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; 

// Combina a configuração estática (vinda do backend, ex: "19:45")
//com o status dinâmico do aluno (ex: "Presente").
class ChamadaComStatus {
  final Map<String, dynamic> config;
  final String? presencaStatus;

  ChamadaComStatus({required this.config, this.presencaStatus});

  String get horaInicio => config['hora_inicio'] ?? '??:??';
  int get rodada => config['rodada'] ?? 0;
  int get duracaoMin => config['duracao_minutos'] ?? 10;
  int get toleranciaMin => config['tolerancia_minutos'] ?? 5;
  int get tempoNormalMin => duracaoMin - toleranciaMin;
}

class EstadoCard {
  final Color color;
  final bool isClickable;

  EstadoCard(this.color, this.isClickable);
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF9B1536);
  static const Color inactiveColor = Color(0xFFD9D9D9); // RF009 (Cinza)
  static const Color activeColor = Color(0xFF007AFF);    // RF010 (Azul) - Cor sugerida
  static const Color presentColor = Color(0xFF34C759);  // RF011 (Verde)
  static const Color lateColor = Color(0xFFFFCC00);     // RF012 (Amarelo)
  static const Color missedColor = Color(0xFFFF3B30);    // RF013 (Vermelho)

  late Future<List<ChamadaComStatus>> _chamadasFuture;
  Timer? _timer;
  DateTime _agora = DateTime.now();
  String _countdownString = "--:--:--";
  int? _alunoId;

  @override
  void initState() {
    super.initState();
    _chamadasFuture = _loadChamadaData();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Atualiza a hora atual e o countdown.
  void _tick(Timer timer) {
    setState(() {
      _agora = DateTime.now();
      _chamadasFuture.then((chamadas) {
        _updateCountdown(chamadas, _agora);
      });
    });
  }

  // Carrega os dados da API:
  // 1. A configuração de horários.
  // 2. Os registros de presença do aluno HOJE.
  //Combina os dois em uma lista de [ChamadaComStatus].
  Future<List<ChamadaComStatus>> _loadChamadaData() async {
    final prefs = await SharedPreferences.getInstance();
    _alunoId = prefs.getInt('aluno_id');

    if (_alunoId == null) {
      if (mounted) AuthService.logout(context); // Força logout se o ID sumir
      throw Exception("ID do aluno não encontrado. Faça login.");
    }

    try {
      // Busca os dois conjuntos de dados em paralelo para mais performance
      final responses = await Future.wait([
        ApiService.getHorarios(),
        ApiService.getPresencasHoje(_alunoId!),
      ]);

      final horariosConfig = (responses[0]['horarios'] as List<dynamic>);
      final presencasHoje = (responses[1]['presencas'] as List<dynamic>);

      // Mapeia as presenças de hoje por rodada para fácil acesso
      // Ex: { 1: "Presente", 3: "Atrasado" }
      final Map<int, String> presencasMap = {
        for (var p in presencasHoje)
          p['rodada']: p['status_presenca']
      };

      // 3. Combina a configuração com o status de presença
      return horariosConfig.map((config) {
        final int rodada = config['rodada'];
        return ChamadaComStatus(
          config: config,
          presencaStatus: presencasMap[rodada], // null se não houver registro
        );
      }).toList();

    } catch (e) {
      // Se falhar (ex: token expirado), força o logout
      if (mounted) AuthService.logout(context);
      rethrow; // Lança o erro para o FutureBuilder tratar
    }
  }

  // Calcula a cor e a clicabilidade de um card com base
  //no status da chamada e na hora atual.
  EstadoCard _calcularEstado(ChamadaComStatus chamada, DateTime agora) {
    if (chamada.presencaStatus == 'Presente') {
      return EstadoCard(presentColor, false); // Verde, não clicável
    }
    if (chamada.presencaStatus == 'Atrasado') {
      return EstadoCard(lateColor, false); // Amarelo, não clicável
    }

    final parts = chamada.horaInicio.split(':').map(int.parse).toList();
    final horaInicioHoje = DateTime(agora.year, agora.month, agora.day, parts[0], parts[1]);

    final horaFimNormal = horaInicioHoje.add(Duration(minutes: chamada.tempoNormalMin));
    final horaFimTotal = horaInicioHoje.add(Duration(minutes: chamada.duracaoMin));

    if (agora.isAfter(horaFimTotal)) {
      if (chamada.presencaStatus == 'Faltou' || chamada.presencaStatus == null) {
         return EstadoCard(missedColor, false); // Vermelho, não clicável
      }
       return EstadoCard(missedColor, false);
    }

    // Chamada está na tolerância?
    if (agora.isAfter(horaFimNormal)) {
      return EstadoCard(activeColor, true); // Azul, clicável
    }

    // 4. Chamada está ativa e no tempo normal?
    if (agora.isAfter(horaInicioHoje)) {
      return EstadoCard(activeColor, true); // Azul, clicável
    }

    // 5. Chamada ainda não começou
    return EstadoCard(inactiveColor, false); // Cinza, não clicável
  }

  // Encontra a próxima chamada e calcula o tempo restante.
  void _updateCountdown(List<ChamadaComStatus> chamadas, DateTime agora) {
    DateTime? proximaChamada;

    // Encontra o próximo horário de início que ainda não passou
    for (var chamada in chamadas) {
      final parts = chamada.horaInicio.split(':').map(int.parse).toList();
      final horaInicioHoje = DateTime(agora.year, agora.month, agora.day, parts[0], parts[1]);
      
      if (horaInicioHoje.isAfter(agora)) {
        proximaChamada = horaInicioHoje;
        break; // Encontrou a próxima
      }
    }

    if (proximaChamada != null) {
      final diff = proximaChamada.difference(agora);
      // Formata a duração em HH:MM:SS
      _countdownString = 
          '${diff.inHours.toString().padLeft(2, '0')}:'
          '${(diff.inMinutes % 60).toString().padLeft(2, '0')}:'
          '${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      _countdownString = "Finalizado"; // Nenhuma chamada restante hoje
    }
  }


  // Ação de registrar a presença (chamada quando o card azul é clicado)
  Future<void> _handleRegistrarPresenca(ChamadaComStatus chamada) async {
    if (_alunoId == null) {
      _showError('Erro: Aluno não logado. Faça login novamente.');
      return;
    }

    // Validações anti-fraude (conforme seu código original)
    bool toqueValidado = true;
    bool movimentoValidado = true;

    try {
      // 1. Buscar o ID da chamada ativa (backend verifica se o prof iniciou)
      _showMessage('Buscando chamada para ${chamada.horaInicio}...');
      final chamadaAtiva = await ApiService.getChamadaAtiva(chamada.horaInicio);
      final int idChamada = chamadaAtiva['id_chamada'];
      
      // 2. Registrar a presença (backend calcula Atrasado/Presente)
      final resultado = await ApiService.registrarPresenca(
        alunoId: _alunoId!,
        idChamada: idChamada,
        validacaoToqueTela: toqueValidado,
        validacaoMovimento: movimentoValidado,
      );

      final status = resultado['status_presenca'] ?? 'registrada';
      _showMessage('Presença $status!', success: true);

      // 3. Atualiza a tela
      setState(() {
        _chamadasFuture = _loadChamadaData();
      });

    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showMessage(String message, {bool success = false}) {
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: success ? Colors.green : Colors.blueGrey
        ),
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
            // Card principal -- Timer
            Card(
              color: primaryColor,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    "Próxima chamada em: $_countdownString", 
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

            // Lista de Chamadas
            Expanded(
              child: FutureBuilder<List<ChamadaComStatus>>(
                future: _chamadasFuture,
                builder: (context, snapshot) {
                  // 1. Carregando
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // 2. Erro (ex: API offline, token inválido)
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  // 3. Sucesso
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final List<ChamadaComStatus> chamadas = snapshot.data!;

                    return ListView.builder(
                      itemCount: chamadas.length,
                      itemBuilder: (context, index) {
                        final chamada = chamadas[index]; 
                        final estado = _calcularEstado(chamada, _agora);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
                          child: GestureDetector(
                            // Só permite clique se o estado for clicável
                            onTap: estado.isClickable 
                              ? () => _handleRegistrarPresenca(chamada) 
                              : null, 
                            child: Card(
                              color: estado.color, // Cor dinâmica
                              elevation: 2,
                              child: SizedBox(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    chamada.horaInicio, 
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: estado.color == inactiveColor 
                                        ? Colors.black 
                                        : Colors.white,
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
                  // 4. Sucesso, mas sem dados
                  return const Center(child: Text('Nenhum horário configurado.'));
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        onLogout: () async {
          AuthService.logout(context); 
        },
        onHome: () {
          // Já está na Home, não faz nada
        },
        onConfig: () {
          Navigator.pushReplacementNamed(context, '/config');
        },
      ),
    );
  }
}