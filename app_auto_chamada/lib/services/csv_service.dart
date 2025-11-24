import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// Flutter Web imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CsvService {
  /// Gera um CSV a partir de uma lista de Map<String, dynamic>
  /// e salva no dispositivo. Abre automaticamente (exceto Web).
  static Future<String> gerarCSV(
    List<Map<String, dynamic>> registros,
    String nomeArquivo,
  ) async {
    final csv = _converterParaCSV(registros);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    if (kIsWeb) {
      return _downloadWeb(bytes, "$nomeArquivo.csv");
    } else {
      return _salvarLocal(bytes, "$nomeArquivo.csv");
    }
  }

  /// Converte os registros em CSV
  static String _converterParaCSV(List<Map<String, dynamic>> dados) {
    if (dados.isEmpty) return "";

    final headers = dados.first.keys.toList();
    final csv = StringBuffer();

    csv.writeln(headers.join(";"));

    for (var item in dados) {
      csv.writeln(headers.map((h) => item[h].toString()).join(";"));
    }

    return csv.toString();
  }

  /// Salva o arquivo localmente (Android, Windows, Linux, macOS)
  static Future<String> _salvarLocal(Uint8List bytes, String filename) async {
    final dir = await getDownloadsDirectory();

    if (dir == null) {
      throw Exception("Não foi possível acessar a pasta Downloads.");
    }

    final path = "${dir.path}/$filename";
    final file = File(path);

    await file.writeAsBytes(bytes);

    // Abre automaticamente
    await OpenFilex.open(path);

    return path;
  }

  /// Faz download no Flutter Web
  static Future<String> _downloadWeb(Uint8List bytes, String filename) async {
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();

    html.Url.revokeObjectUrl(url);

    return "Arquivo baixado via navegador";
  }
}
