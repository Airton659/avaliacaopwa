import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/employee_provider.dart';
// import '../services/google_sheets_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Importação de Dados',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Importar funcionários do Google Sheets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Esta operação irá sincronizar os dados dos funcionários '
                      'a partir da planilha Google Sheets configurada.',
                    ),
                    const SizedBox(height: 24),
                    if (_isImporting)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        onPressed: _importFromSheets,
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Sincronizar Dados'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Configurações',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.key),
                title: const Text('Alterar Senha Administrativa'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _changePassword,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações do Google Sheets'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _configureSheets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromSheets() async {
    setState(() {
      _isImporting = true;
    });

    try {
      // TODO: Implementar configuração real das credenciais
      // Por enquanto, mostra mensagem de que precisa configurar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Para usar esta funcionalidade, configure as credenciais '
              'do Google Sheets no menu Configurações.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Quando implementado:
      // final sheetsService = GoogleSheetsService(
      //   spreadsheetId: 'SEU_SPREADSHEET_ID',
      //   credentialsJson: 'SEU_JSON_CREDENTIALS',
      // );
      // final employees = await sheetsService.importEmployees();
      // await context.read<EmployeeProvider>().importFromGoogleSheets(employees);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: const Text(
          'Funcionalidade em desenvolvimento. Por enquanto, a senha padrão é "admin123".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _configureSheets() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Google Sheets'),
        content: const Text(
          'Para configurar a integração com Google Sheets:\n\n'
          '1. Crie um projeto no Google Cloud Console\n'
          '2. Ative a Google Sheets API\n'
          '3. Crie uma Service Account\n'
          '4. Faça download do arquivo JSON de credenciais\n'
          '5. Configure o ID da planilha e as credenciais no código',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
