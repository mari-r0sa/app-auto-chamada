import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_filex/open_filex.dart';

class DownloadService {
  static Future<String?> downloadArquivo(String url, String nomeArquivo) async {
    try {
      final dio = Dio();

      // Baixa os bytes do arquivo
      final response = await dio.get<Uint8List>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );

      final fileData = response.data;
      if (fileData == null) throw Exception("Falha ao baixar o arquivo");

      final params = SaveFileDialogParams(
        data: fileData,
        fileName: nomeArquivo,
        mimeTypesFilter: ['text/csv'], // Android filtra por CSV
        localOnly: false, // opcional, permite acesso completo
      );

      final filePath = await FlutterFileDialog.saveFile(params: params);

      if (filePath != null) {
        await OpenFilex.open(filePath);
      }

      return filePath;
    } catch (e) {
      print("Erro ao baixar CSV: $e");
      rethrow;
    }
  }
}
