// Arquivo principal do serviço de CSV.
// As telas importam ESTE arquivo e chamam gerarCSV(...).

// Importa explicitamente a interface/base.
import 'csv_service_stub.dart';

// Import condicional da implementação concreta:
// - Na Web, usa csv_service_web.dart (que define CsvServiceImpl).
// - Em Android/iOS/desktop, usa csv_service_mobile.dart (também CsvServiceImpl).
import 'csv_service_web.dart'
    if (dart.library.io) 'csv_service_mobile.dart';

/// Instância única da implementação concreta do serviço.
/// Em tempo de compilação, CsvServiceImpl vem do arquivo correto (web ou mobile).
final CsvServiceBase _impl = CsvServiceImpl();

/// Função que as telas usam para gerar o CSV.
/// Exemplo de uso:
/// await gerarCSV(registros, "relatorio");
Future<String> gerarCSV(
  List<Map<String, dynamic>> registros,
  String nomeArquivo,
) {
  return _impl.gerarCSV(registros, nomeArquivo);
}
