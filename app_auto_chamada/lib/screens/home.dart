import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_bar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Combina a configuração da chamada do backend + status do aluno
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

/// Estado visual de um card
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
  // Cores do sistema
  static const Color primaryColor = Color(0xFF9B1536);
  static const Color inactiveColor = Color(0xFFD9D9D9);
  static const Color activeColor = Color(0xFF007AFF);
  static const Color presentColor = Color(0xFF34C759);
  static const Color lateColor = Color(0xFFFFCC00);
  static const Color missedColor = Color(0xFFFF3B30);

  List<ChamadaComStatus> _chamadas = [];
  Timer? _timer;
  DateTime _agora = DateTime.now();
  String _countdownString = "--:--:--";
  int? _alunoId;

  // Controle de refresh suave
  DateTime _ultimoRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration refreshInterval = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _carregarChamadas();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Tick atualiza somente countdown
  // E recarrega as chamadas a cada 30s
  void _tick() {
    setState(() {
      _agora = DateTime.now();
    });

    _updateCountdown(_chamadas, _agora);

    if (DateTime.now().difference(_ultimoRefresh) > refreshInterval) {
      _carregarChamadas();
    }
  }

  Future<void> _carregarChamadas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _alunoId = prefs.getInt('user_id');

      if (_alunoId == null) {
        AuthService.logout(context);
        return;
      }

      final responses = await Future.wait([
        ApiService.getHorarios(),
        ApiService.getPresencasHoje(_alunoId!),
      ]);

      final horariosConfig = (responses[0]['horarios'] as List<dynamic>);
      final presencasHoje = (responses[1]['presencas'] as List<dynamic>);

      final Map<int, String> presencasMap = {
        for (var p in presencasHoje) p['rodada']: p['status_presenca']
      };

      setState(() {
        _chamadas = horariosConfig.map((config) {
          final rodada = config['rodada'];
          return ChamadaComStatus(
            config: config,
            presencaStatus: presencasMap[rodada],
          );
        }).toList();

        _ultimoRefresh = DateTime.now();
      });
    } catch (e) {
      AuthService.logout(context);
    }
  }

  // --- Lógica de exibição do card ---
  EstadoCard _calcularEstado(ChamadaComStatus chamada, DateTime agora) {
    if (chamada.presencaStatus == 'Presente') {
      return EstadoCard(presentColor, false);
    }
    if (chamada.presencaStatus == 'Atrasado') {
      return EstadoCard(lateColor, false);
    }

    final partes = chamada.horaInicio.split(':').map(int.parse).toList();
    final horaInicio = DateTime(agora.year, agora.month, agora.day, partes[0], partes[1]);

    final fimNormal = horaInicio.add(Duration(minutes: chamada.tempoNormalMin));
    final fimTotal = horaInicio.add(Duration(minutes: chamada.duracaoMin));

    if (agora.isAfter(fimTotal)) {
      return EstadoCard(missedColor, false);
    }

    // Período ativo (normal + tolerância)
    if (agora.isAfter(horaInicio)) {
      return EstadoCard(activeColor, true);
    }

    return EstadoCard(inactiveColor, false);
  }

  // Countdown até a próxima chamada
  void _updateCountdown(List<ChamadaComStatus> chamadas, DateTime agora) {
    DateTime? proxima;

    for (var chamada in chamadas) {
      final partes = chamada.horaInicio.split(':').map(int.parse).toList();
      final inicio = DateTime(agora.year, agora.month, agora.day, partes[0], partes[1]);

      if (inicio.isAfter(agora)) {
        proxima = inicio;
        break;
      }
    }

    if (proxima == null) {
      _countdownString = "Finalizado";
      return;
    }

    final diff = proxima.difference(agora);

    setState(() {
      _countdownString =
          "${diff.inHours.toString().padLeft(2, '0')}:"
          "${(diff.inMinutes % 60).toString().padLeft(2, '0')}:"
          "${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
    });
  }

  Future<({double lat, double lng})> _obterLocalizacao() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Permissão de localização negada.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Acesso à localização permanentemente negado.");
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return (lat: pos.latitude, lng: pos.longitude);
  }

  // Registrar presença
  Future<void> _handleRegistrarPresenca(ChamadaComStatus chamada) async {
    try {
      if (_alunoId == null) return;

      // 1. obter localização antes de registrar
      final loc = await _obterLocalizacao();

      // 2. pegar id da chamada ativa
      final chamadaAtiva = await ApiService.getChamadaAtiva(chamada.horaInicio);
      final int idChamada = chamadaAtiva['id_chamada'];

      // 3. registrar presença
      final resultado = await ApiService.registrarPresenca(
        alunoId: _alunoId!,
        idChamada: idChamada,
        latitude: loc.lat,
        longitude: loc.lng,
      );

      _showMessage(
        "Presença ${resultado['status_presenca']}!",
        success: true,
      );

      await _carregarChamadas();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.blueGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Auto-chamada"),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Card do countdown
            Card(
              color: primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
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

            // Lista de chamadas
            Expanded(
              child: _chamadas.isEmpty
                  ? const Center(child: Text("Nenhum horário configurado."))
                  : ListView.builder(
                      itemCount: _chamadas.length,
                      itemBuilder: (_, index) {
                        final chamada = _chamadas[index];
                        final estado = _calcularEstado(chamada, _agora);

                        return GestureDetector(
                          onTap: estado.isClickable
                              ? () => _handleRegistrarPresenca(chamada)
                              : null,
                          child: Card(
                            color: estado.color,
                            child: SizedBox(
                              height: 60,
                              child: Center(
                                child: Text(
                                  chamada.horaInicio,
                                  style: TextStyle(
                                    color: estado.color == inactiveColor
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomBar(
        onLogout: () => AuthService.logout(context),
        onHome: () {},
        onConfig: () {
          Navigator.pushReplacementNamed(context, '/config');
        },
      ),
    );
  }
}