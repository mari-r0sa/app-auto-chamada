// Implementação do serviço de CSV para plataformas nativas
// (Android, iOS, Windows, Linux, macOS). Aqui NÃO usamos dart:html.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'csv_service_stub.dart';

/// Implementação do serviço de CSV específica para mobile/desktop.
class CsvServiceImpl implements CsvServiceBase {
  @override
  Future<String> gerarCSV(
    List<Map<String, dynamic>> registros,
    String nomeArquivo,
  ) async {
    final csv = _converterParaCSV(registros);
    final bom = [0xEF, 0xBB, 0xBF];
    final csvBytes = utf8.encode(csv);
    final bytes = Uint8List.fromList([...bom, ...csvBytes]);
    return _salvarLocal(bytes, "$nomeArquivo.csv");
  }

  /// Converte a lista de Map em uma string CSV separada por ponto e vírgula.
  String _converterParaCSV(List<Map<String, dynamic>> dados) {
    if (dados.isEmpty) return "";

    final headers = dados.first.keys.toList();
    final csv = StringBuffer();

    csv.writeln(headers.join(";"));

    for (var item in dados) {
      csv.writeln(headers.map((h) {
        final value = item[h].toString().replaceAll('"', '""');
        return '"$value"';
      }).join(";"));
    }

    return csv.toString();
  }

  /// Salva o arquivo na pasta Downloads e tenta abrir.
  Future<String> _salvarLocal(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();

    final path = "${dir.path}/$filename";
    final file = File(path);

    await file.writeAsBytes(bytes);

    // abre com qualquer app que suporte CSV
    await OpenFilex.open(path);

    return path;
  }
}
