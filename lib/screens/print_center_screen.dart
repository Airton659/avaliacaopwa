import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/evaluation.dart';
import '../models/evaluation_type.dart';
import '../providers/evaluation_provider.dart';
import '../services/pdf_service.dart';

class PrintCenterScreen extends StatefulWidget {
  const PrintCenterScreen({super.key});

  @override
  State<PrintCenterScreen> createState() => _PrintCenterScreenState();
}

class _PrintCenterScreenState extends State<PrintCenterScreen> {
  int _selectedYear = DateTime.now().year;
  EvaluationType? _selectedDocType;
  String _searchQuery = '';
  final PdfService _pdfService = PdfService();

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  void _loadEvaluations() {
    context.read<EvaluationProvider>().loadEvaluationsByYear(_selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Impressão'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildEvaluationsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Ano',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                        });
                        _loadEvaluations();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<EvaluationType>(
                    value: _selectedDocType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Documento',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...EvaluationType.values
                          .where((type) =>
                              type == EvaluationType.autoOperacional ||
                              type == EvaluationType.gestorOperacional ||
                              type == EvaluationType.autoGerencial ||
                              type == EvaluationType.gestorGerencial ||
                              type == EvaluationType.finalOperacional ||
                              type == EvaluationType.finalGerencial)
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDocType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por Nome ou Chapa',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationsList() {
    return Consumer<EvaluationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var evaluations = provider.evaluations;

        // Filtro por tipo de documento
        if (_selectedDocType != null) {
          evaluations = evaluations
              .where((eval) => eval.type == _selectedDocType)
              .toList();
        }

        // Filtro por busca
        if (_searchQuery.isNotEmpty) {
          evaluations = evaluations.where((eval) {
            final nome = eval.employeeSnapshot.nome.toLowerCase();
            final id = eval.id.toLowerCase();
            return nome.contains(_searchQuery) || id.contains(_searchQuery);
          }).toList();
        }

        // Agrupa por funcionário
        final Map<String, List<dynamic>> groupedByEmployee = {};
        for (final eval in evaluations) {
          final employeeName = eval.employeeSnapshot.nome;
          groupedByEmployee.putIfAbsent(employeeName, () => []).add(eval);
        }

        if (groupedByEmployee.isEmpty) {
          return const Center(
            child: Text('Nenhuma avaliação encontrada'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedByEmployee.length,
          itemBuilder: (context, index) {
            final employeeName = groupedByEmployee.keys.elementAt(index);
            final employeeEvals = groupedByEmployee[employeeName]!;
            final snapshot = employeeEvals.first.employeeSnapshot;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  employeeName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${snapshot.funcao} - ${snapshot.nivel} | ${employeeEvals.length} avaliações',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações do Funcionário:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Função: ${snapshot.funcao}'),
                        Text('Nível: ${snapshot.nivel}'),
                        Text('Faixa: ${snapshot.faixa}'),
                        Text('Admissão: ${snapshot.admissao}'),
                        const Divider(height: 24),
                        const Text(
                          'Documentos Disponíveis:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...employeeEvals.map((eval) => ListTile(
                              leading: const Icon(Icons.description),
                              title: Text(eval.type.label),
                              subtitle: Text(
                                'Média: ${eval.average.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.print),
                                onPressed: () =>
                                    _printDocument([eval], eval.type),
                              ),
                            )),
                        const Divider(height: 24),
                        // Botão para gerar relatório consolidado
                        if (_hasCompletePair(employeeEvals))
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _printConsolidatedReport(employeeEvals),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Gerar Relatório Final'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _hasCompletePair(List<dynamic> evaluations) {
    final hasAuto = evaluations.any((e) =>
        e.type == EvaluationType.autoOperacional ||
        e.type == EvaluationType.autoGerencial);
    final hasGestor = evaluations.any((e) =>
        e.type == EvaluationType.gestorOperacional ||
        e.type == EvaluationType.gestorGerencial);
    return hasAuto && hasGestor;
  }

  Future<void> _printDocument(
    List<dynamic> evaluations,
    EvaluationType type,
  ) async {
    try {
      await _pdfService.generateAndPrintPdf(
        evaluations.cast<Evaluation>(),
        type,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printConsolidatedReport(List<dynamic> evaluations) async {
    try {
      // Determina se é operacional ou gerencial
      final isGerencial = evaluations.any(
        (e) => e.type == EvaluationType.autoGerencial ||
            e.type == EvaluationType.gestorGerencial,
      );

      final reportType = isGerencial
          ? EvaluationType.finalGerencial
          : EvaluationType.finalOperacional;

      await _pdfService.generateAndPrintPdf(
        evaluations.cast<Evaluation>(),
        reportType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar relatório: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
