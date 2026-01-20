import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import '../models/employee_with_evaluations.dart';
import '../services/pdf_service.dart';
import '../services/firebase_service.dart';
import '../utils/situacao_helper.dart';

class CentralImpressaoScreen extends StatefulWidget {
  const CentralImpressaoScreen({super.key});

  @override
  State<CentralImpressaoScreen> createState() => _CentralImpressaoScreenState();
}

class _CentralImpressaoScreenState extends State<CentralImpressaoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _filtroSituacao;
  int _selectedYear = DateTime.now().year;
  bool _keepSelection = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> _getCurrentCycle() async {
    try {
      final configDoc = await _firestore.collection('config').doc('general').get();
      final cycleStr = configDoc.data()?['currentCycle']?.toString() ?? DateTime.now().year.toString();
      return int.tryParse(cycleStr) ?? DateTime.now().year;
    } catch (e) {
      return DateTime.now().year;
    }
  }

  Future<List<EmployeeWithEvaluations>> _getEmployeesWithEvaluations() async {
    final employeesSnapshot = await _firestore.collection('funcionarios').where('situacao', isEqualTo: 'Ativo').get();
    
    // FETCH OPTIMIZATION: Get all evaluations for the year in ONE query
    // instead of N queries per employee.
    final yearStr = _selectedYear.toString();
    final evaluationsSnapshot = await _firestore
        .collection('evaluations')
        .where('ano', isEqualTo: yearStr)
        .get();

    // Create a lookup map for evaluations: Map<DocId, Data>
    final Map<String, Map<String, dynamic>> evaluationsMap = {};
    for (var doc in evaluationsSnapshot.docs) {
      evaluationsMap[doc.id] = doc.data();
    }
    
    final List<EmployeeWithEvaluations> result = [];

    // 2. For each employee, lookup in local map
    for (final doc in employeesSnapshot.docs) {
      final data = doc.data();
      final chapa = doc.id;

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final nome = (data['nome']?.toString() ?? '').toLowerCase();
        final chapaLower = chapa.toLowerCase();
        if (!nome.contains(_searchQuery) && !chapaLower.contains(_searchQuery)) {
          continue;
        }
      }

      // Apply situacao filter
      if (_filtroSituacao != null) {
        final situacao = data['situacao']?.toString() ?? '';
        if (situacao.toUpperCase() != _filtroSituacao) {
          continue;
        }
      }

      // Lookup evaluations using known ID pattern
      // docId pattern: {year}_{chapa}_{TYPE}
      // Note: FormularioAvaliacaoScreen saves using 'ano' as string.
      final autoDocId = '${_selectedYear}_${chapa}_AUTO';
      final gestorDocId = '${_selectedYear}_${chapa}_GESTOR';

      final autoData = evaluationsMap[autoDocId];
      final gestorData = evaluationsMap[gestorDocId];

      final employeeWithEval = EmployeeWithEvaluations(
        chapa: chapa,
        nome: data['nome']?.toString() ?? '',
        funcao: data['funcao']?.toString() ?? '',
        nivel: data['nivel']?.toString(),
        situacao: data['situacao']?.toString() ?? '',
        isManager: data['isManager'] ?? false,
        autoEvaluation: autoData,
        gestorEvaluation: gestorData,
      );

      // Only include if has at least one evaluation
      if (employeeWithEval.hasAnyEvaluation) {
        result.add(employeeWithEval);
      }
    }

    // Sort by name
    result.sort((a, b) => a.nome.compareTo(b.nome));

    return result;
  }

  Future<void> _generatePDF(EmployeeWithEvaluations employeeData, String anexoType) async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get employee full data
      final employee = await _firebaseService.getEmployeeById(employeeData.chapa);
      if (employee == null) throw Exception('Funcionário não encontrado');

      // Get questions (OPERACIONAL or GERENCIAL)
      final questionType = employeeData.isManager ? 'GERENCIAL' : 'OPERACIONAL';
      final questions = await _firebaseService.getQuestions();
      final filteredQuestions = questions
          .where((q) => q.tipo == questionType && q.ativo)
          .toList();
      
      final questionsMap = filteredQuestions.map((q) {
        final data = q.toFirestore();
        data['id'] = q.id;
        return data;
      }).toList();

      // Convert evaluation maps to Evaluation objects
      final autoEval = employeeData.autoEvaluation != null 
          ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_AUTO')
          : null;
      final gestorEval = employeeData.gestorEvaluation != null
          ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_GESTOR')
          : null;

      // Generate PDF bytes
      final pdfService = PdfService();
      late Uint8List pdfBytes;

      switch (anexoType) {
        case 'I':
          pdfBytes = await pdfService.generateAnexoI(employee, autoEval, questionsMap, _selectedYear);
          break;
        case 'II':
          pdfBytes = await pdfService.generateAnexoII(employee, gestorEval, questionsMap, _selectedYear);
          break;
        case 'III':
          pdfBytes = await pdfService.generateAnexoIII(employee, autoEval, gestorEval, questionsMap, _selectedYear);
          break;
        case 'IV':
          pdfBytes = await pdfService.generateAnexoIV(employee, autoEval, questionsMap, _selectedYear);
          break;
        case 'V':
          pdfBytes = await pdfService.generateAnexoV(employee, gestorEval, questionsMap, _selectedYear);
          break;
        case 'VI':
          pdfBytes = await pdfService.generateAnexoVI(employee, autoEval, gestorEval, questionsMap, _selectedYear);
          break;
        default:
          throw Exception('Tipo de anexo inválido');
      }

      // Close loading
      if (mounted) Navigator.pop(context);

      // Open print dialog
      if (mounted) {
        await Printing.layoutPdf(onLayout: (_) => Future.value(pdfBytes));
      }
    } catch (e) {
      // Close loading if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Impressão'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          // Filters section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    // Year selector
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Ano',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Search field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar por Nome ou Chapa',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Situacao filter (populated dynamically similar to other screens)
                    Expanded(
                      child: FutureBuilder<List<String>>(
                        future: _getAvailableSituacoes(),
                        builder: (context, snapshot) {
                          final situacoes = snapshot.data ?? [];
                          return DropdownButtonFormField<String>(
                            value: _filtroSituacao,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por Situação',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Todas'),
                              ),
                              ...situacoes.map((sit) {
                                final descricao = SituacaoHelper.situacoes[sit] ?? sit;
                                return DropdownMenuItem<String>(
                                  value: sit,
                                  child: Text('$sit - $descricao'),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filtroSituacao = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Keep selection checkbox
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Manter seleção ao imprimir'),
                        value: _keepSelection,
                        onChanged: (value) {
                          setState(() {
                            _keepSelection = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Employee list
          Expanded(
            child: FutureBuilder<List<EmployeeWithEvaluations>>(
              future: _getEmployeesWithEvaluations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${snapshot.error}'),
                  );
                }

                final employees = snapshot.data ?? [];

                if (employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma avaliação encontrada',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    return _buildEmployeeCard(employees[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeWithEvaluations employeeData) {
    final statusColor = employeeData.statusColor == 'green'
        ? Colors.green
        : employeeData.statusColor == 'orange'
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            employeeData.nome,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${employeeData.chapa})',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (employeeData.isManager) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'GESTOR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employeeData.funcao,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        SituacaoHelper.getDescricaoCompleta(employeeData.situacao),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 12, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        employeeData.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Anexo buttons
            Row(
              children: [
                const Text(
                  'Anexos: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
                if (!employeeData.isManager) ...[
                  // Operacional: Anexos I, II, III
                  _buildAnexoButton('I', employeeData, employeeData.autoEvaluation != null),
                  const SizedBox(width: 8),
                  _buildAnexoButton('II', employeeData, employeeData.gestorEvaluation != null),
                  const SizedBox(width: 8),
                  _buildAnexoButton('III', employeeData, 
                      employeeData.autoEvaluation != null && employeeData.gestorEvaluation != null),
                ] else ...[
                  // Gerencial: Anexos IV, V, VI
                  _buildAnexoButton('IV', employeeData, employeeData.autoEvaluation != null),
                  const SizedBox(width: 8),
                  _buildAnexoButton('V', employeeData, employeeData.gestorEvaluation != null),
                  const SizedBox(width: 8),
                  _buildAnexoButton('VI', employeeData,
                      employeeData.autoEvaluation != null && employeeData.gestorEvaluation != null),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnexoButton(String anexoType, EmployeeWithEvaluations employeeData, bool isAvailable) {
    return ElevatedButton(
      onPressed: isAvailable
          ? () => _generatePDF(employeeData, anexoType)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isAvailable ? Colors.blue.shade700 : Colors.grey.shade300,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(50, 40),
      ),
      child: Text(
        anexoType,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Future<List<String>> _getAvailableSituacoes() async {
    try {
      final snapshot = await _firestore
          .collection('funcionarios')
          .where('ativo', isEqualTo: true)
          .get();

      final situacoes = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final situacao = data['situacao']?.toString() ?? '';
        if (situacao.isNotEmpty) {
          situacoes.add(situacao.toUpperCase());
        }
      }

      final list = situacoes.toList()..sort();
      return list;
    } catch (e) {
      return [];
    }
  }
}
