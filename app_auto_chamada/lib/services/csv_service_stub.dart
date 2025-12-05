// Define a interface/base do serviço de CSV, que diz QUAL função existe, mas não como ela é implementada.

import 'dart:typed_data';

abstract class CsvServiceBase {
  // Gera um arquivo CSV a partir de uma lista de mapas e retorna uma mensagem/caminho quando terminar.
  Future<String> gerarCSV(
    List<Map<String, dynamic>> registros,
    String nomeArquivo,
  );
}
