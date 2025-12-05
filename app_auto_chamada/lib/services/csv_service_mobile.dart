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
    final bytes = Uint8List.fromList(utf8.encode(csv));
    return _salvarLocal(bytes, "$nomeArquivo.csv");
  }

  /// Converte a lista de Map em uma string CSV separada por ponto e vírgula.
  String _converterParaCSV(List<Map<String, dynamic>> dados) {
    if (dados.isEmpty) return "";

    final headers = dados.first.keys.toList();
    final csv = StringBuffer();

    csv.writeln(headers.join(";"));

    for (var item in dados) {
      csv.writeln(headers.map((h) => item[h].toString()).join(";"));
    }

    return csv.toString();
  }

  /// Salva o arquivo na pasta Downloads e tenta abrir.
  Future<String> _salvarLocal(Uint8List bytes, String filename) async {
    final dir = await getDownloadsDirectory();

    if (dir == null) {
      throw Exception("Não foi possível acessar a pasta Downloads.");
    }

    final path = "${dir.path}/$filename";
    final file = File(path);

    await file.writeAsBytes(bytes);

    await OpenFilex.open(path);

    return path;
  }
}
