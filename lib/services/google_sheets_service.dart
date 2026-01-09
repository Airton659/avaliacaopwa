import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import '../models/employee.dart';

class GoogleSheetsService {
  final String spreadsheetId;
  final String credentialsJson;

  GoogleSheetsService({
    required this.spreadsheetId,
    required this.credentialsJson,
  });

  Future<List<Employee>> importEmployees() async {
    // TODO: Implementar autenticação com Service Account
    // Por enquanto, retorna lista vazia.
    // Será necessário configurar as credenciais do Google Cloud

    final employees = <Employee>[];

    try {
      // Autenticação usando Service Account
      final accountCredentials = ServiceAccountCredentials.fromJson(
        credentialsJson,
      );

      final scopes = [sheets.SheetsApi.spreadsheetsReadonlyScope];

      final client = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      final sheetsApi = sheets.SheetsApi(client);

      // Lê dados da planilha (assumindo que os dados estão na aba "Dados" range A2:H)
      final response = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'Dados!A2:H1000',
      );

      final values = response.values;
      if (values == null || values.isEmpty) {
        return employees;
      }

      // Mapeia as colunas conforme especificação:
      // 0: CHAPA, 1: NOME, 2: DATA_ADMISSAO, 3: FUNCAO,
      // 4: NOMENIVEL, 5: NOMEFAIXA, 6: CODSITUACAO
      for (final row in values) {
        if (row.length < 7) continue; // Pula linhas incompletas

        final employee = Employee(
          id: row[0].toString().trim(),
          nome: row[1].toString().trim(),
          admissao: row[2].toString().trim(),
          funcao: row[3].toString().trim(),
          nivel: row[4].toString().trim(),
          faixa: row[5].toString().trim(),
          situacao: row[6].toString().trim(),
          isManager: false,
          managerId: null,
        );

        employees.add(employee);
      }

      client.close();
    } catch (e) {
      throw Exception('Erro ao importar planilha: $e');
    }

    return employees;
  }
}
