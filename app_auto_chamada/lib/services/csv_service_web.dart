// Implementação do serviço de CSV específica para Flutter Web.
// Aqui PODE usar dart:html, porque só será compilado para web.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

import 'csv_service_stub.dart';

class CsvServiceImpl implements CsvServiceBase {
  @override
  Future<String> gerarCSV(
    List<Map<String, dynamic>> registros,
    String nomeArquivo,
  ) async {
    final csv = _converterParaCSV(registros);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    return _downloadWeb(bytes, "$nomeArquivo.csv");
  }

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

  Future<String> _downloadWeb(Uint8List bytes, String filename) async {
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();

    html.Url.revokeObjectUrl(url);

    return "Arquivo baixado via navegador";
  }
}
