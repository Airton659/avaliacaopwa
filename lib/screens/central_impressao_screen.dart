import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/employee_with_evaluations.dart';
import '../services/pdf_service.dart';
import '../services/firebase_service.dart';
import '../utils/situacao_helper.dart';
import '../widgets/multi_situacao_filter.dart';
import '../widgets/multi_tipo_filter.dart';
import '../widgets/expandable_filter_section.dart';
import '../models/commission_president.dart';

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
  Set<String> _filtrosSituacao = {};
  Set<String> _filtrosTipo = {};
  int _selectedYear = DateTime.now().year;
  bool _keepSelection = false;
  
  // Bulk Selection State
  final Set<String> _selectedAnexos = {}; // e.g., {'I', 'II'}
  final Set<String> _selectedEmployees = {}; // Stores checked employee 'chapa's

  void _toggleAnexo(String key, bool selected) {
    setState(() {
      if (selected) {
        // Exclusion Logic:
        // Group A: I, II, III (Operacional)
        // Group B: IV, V, VI (Gerencial)
        if (['I', 'II', 'III'].contains(key)) {
           _selectedAnexos.removeWhere((k) => ['IV', 'V', 'VI'].contains(k));
        } else if (['IV', 'V', 'VI'].contains(key)) {
           _selectedAnexos.removeWhere((k) => ['I', 'II', 'III'].contains(k));
        }
        _selectedAnexos.add(key);
      } else {
        _selectedAnexos.remove(key);
      }
    });
  }

  void _toggleEmployee(String chapa, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedEmployees.add(chapa);
      } else {
        _selectedEmployees.remove(chapa);
      }
    });
  }

  void _toggleAll(List<EmployeeWithEvaluations> currentList) {
    final allChapas = currentList.map((e) => e.chapa).toSet();
    final allSelected = allChapas.every((c) => _selectedEmployees.contains(c));
    
    setState(() {
      if (allSelected) {
        _selectedEmployees.removeAll(allChapas);
      } else {
        _selectedEmployees.addAll(allChapas);
      }
    });
  }

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
    final employeesSnapshot = await _firestore.collection('funcionarios').get();
    
    // FETCH OPTIMIZATION: Get all evaluations for the year in ONE query
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

      // Apply situacao filter (multi-selection)
      if (_filtrosSituacao.isNotEmpty) {
        final situacao = data['situacao']?.toString() ?? '';
        if (!_filtrosSituacao.contains(situacao.toUpperCase())) {
          continue;
        }
      }

      // Apply tipo filter (multi-selection)
      if (_filtrosTipo.isNotEmpty) {
        final tipo = data['codtipo']?.toString() ?? '';
        if (!_filtrosTipo.contains(tipo.toUpperCase())) {
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

      // Anexo Filter
      if (_selectedAnexos.isNotEmpty) {
        bool match = false;
        
        // Check Operacional Anexos (I, II, III)
        if (!employeeWithEval.isManager) {
           if (_selectedAnexos.contains('I') && employeeWithEval.autoEvaluation != null) match = true;
           if (_selectedAnexos.contains('II') && employeeWithEval.gestorEvaluation != null) match = true;
           if (_selectedAnexos.contains('III') && employeeWithEval.hasAnyEvaluation) match = true;
        } 
        
        // Check Gerencial Anexos (IV, V, VI)
        if (employeeWithEval.isManager) { 
           if (_selectedAnexos.contains('IV') && employeeWithEval.autoEvaluation != null) match = true;
           if (_selectedAnexos.contains('V') && employeeWithEval.gestorEvaluation != null) match = true;
           if (_selectedAnexos.contains('VI') && employeeWithEval.hasAnyEvaluation) match = true;
        }

        if (!match) continue;
      }

      // Only include if has at least one evaluation
      if (employeeWithEval.hasAnyEvaluation) {
        result.add(employeeWithEval);
      }
    }

    // Sort by name
    result.sort((a, b) => a.nome.compareTo(b.nome));

    return result;
  }

  Future<CommissionPresident?> _getCommissionPresident() async {
    try {
      final query = await _firestore
          .collection('comissao')
          .where('isPresident', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        
        String name = data['nome'] ?? 'Presidente da Comissão';
        
        // Fallback: If name is default or missing, try fetching from FUNCIONARIOS collection (Source of Truth)
        if (name == 'Presidente da Comissão' || name.isEmpty) {
           try {
             // Try 'funcionarios' first (Correct collection for employees)
             var userDoc = await _firestore.collection('funcionarios').doc(doc.id).get();
             
             // If not found, try 'users' (Legacy/Auth)
             if (!userDoc.exists) {
                userDoc = await _firestore.collection('users').doc(doc.id).get();
             }

             if (userDoc.exists && userDoc.data() != null) {
                final userData = userDoc.data()!;
                if (userData['nome'] != null) name = userData['nome'];
                else if (userData['name'] != null) name = userData['name'];
             }
           } catch (_) {}
        }

        if (data['signatureUrl'] != null && data['signatureUrl'].isNotEmpty) {
          return CommissionPresident(
            name: name,
            signatureUrl: data['signatureUrl'],
            metadata: data['signatureMetadata'] ?? {},
          );
        }
      }
    } catch (e) {
      print('Erro ao buscar presidente: $e');
    }
    return null;
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
      final president = await _getCommissionPresident();
      late Uint8List pdfBytes;

      switch (anexoType) {
        case 'I':
          pdfBytes = await pdfService.generateAnexoI(employee, autoEval, questionsMap, _selectedYear, president: president);
          break;
        case 'II':
          pdfBytes = await pdfService.generateAnexoII(employee, gestorEval, questionsMap, _selectedYear, president: president);
          break;
        case 'III':
          pdfBytes = await pdfService.generateAnexoIII(employee, autoEval, gestorEval, questionsMap, _selectedYear, president: president);
          break;
        case 'IV':
          pdfBytes = await pdfService.generateAnexoIV(employee, autoEval, questionsMap, _selectedYear, president: president);
          break;
        case 'V':
          pdfBytes = await pdfService.generateAnexoV(employee, gestorEval, questionsMap, _selectedYear, president: president);
          break;
        case 'VI':
          pdfBytes = await pdfService.generateAnexoVI(employee, autoEval, gestorEval, questionsMap, _selectedYear, president: president);
          break;
        default:
          throw Exception('Tipo de anexo inválido');
      }

      // Close loading
      if (mounted) Navigator.pop(context);

      // Open print dialog with Fallback
                     // Open print dialog
      if (mounted) {
        try {
           if (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
               // iOS Web specific: Use sharePdf to trigger native Share Sheet (contains Print)
               await Printing.sharePdf(bytes: pdfBytes, filename: 'Relatorio_${employeeData.chapa}_$anexoType.pdf');
           } else {
               await Printing.layoutPdf(
                 onLayout: (_) => Future.value(pdfBytes),
                 name: 'Relatorio_${employeeData.chapa}_$anexoType.pdf',
               );
           }
        } catch (printError) {
           print('Erro ao imprimir: $printError');
           if (mounted) {
             // Fallback to Share
             showDialog(
               context: context,
               builder: (context) => AlertDialog(
                 title: const Text('Erro na Impressão'),
                 content: const Text('Ocorreu um erro ao abrir a caixa de impressão. Deseja tentar compartilhar o arquivo PDF?'),
                 actions: [
                   TextButton(
                     onPressed: () => Navigator.pop(context),
                     child: const Text('Cancelar'),
                   ),
                   ElevatedButton(
                     onPressed: () {
                       Navigator.pop(context);
                       Printing.sharePdf(bytes: pdfBytes, filename: 'Relatorio_${employeeData.chapa}_$anexoType.pdf');
                     },
                     child: const Text('Compartilhar PDF'),
                   ),
                 ],
               ),
             );
           }
        }
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

  Future<void> _generateBulkPDF(List<EmployeeWithEvaluations> allEmployees) async {
    if (_selectedEmployees.isEmpty || _selectedAnexos.isEmpty) return;

    // Filter list to selected IDs
    final selectedList = allEmployees.where((e) => _selectedEmployees.contains(e.chapa)).toList();
    
    // Progress State
    int processed = 0;
    int total = selectedList.length * _selectedAnexos.length;
    
    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
             return AlertDialog(
               title: const Text('Gerando Relatórios...'),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   LinearProgressIndicator(),
                   const SizedBox(height: 10),
                   Text('Processando documentação... Aguarde.'),
                 ],
               ),
             );
          }
        );
      }
    );

    try {
      final pdfService = PdfService();
      final president = await _getCommissionPresident();
      final pdf = pw.Document();
      
      // Cache questions
      final allQuestions = await _firebaseService.getQuestions();

      // Iterate
      for (var employeeData in selectedList) {
        // Yield to UI
        await Future.delayed(Duration.zero);
        
        // Fetch full employee
        final employee = await _firebaseService.getEmployeeById(employeeData.chapa);
        if (employee == null) continue;

        // Data Prep
        final autoEval = employeeData.autoEvaluation != null 
             ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_AUTO')
             : null;
        final gestorEval = employeeData.gestorEvaluation != null
             ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_GESTOR')
             : null;

        // Process selected anexos
        for (var anexo in _selectedAnexos) {
          String roleType = 'OPERACIONAL';
          if (['IV', 'V', 'VI'].contains(anexo)) roleType = 'GERENCIAL';
          
          // Filter Questions for this anexo/role
          final filteredQuestions = allQuestions
             .where((q) => q.tipo == roleType && q.ativo)
             .map((q) {
                final data = q.toFirestore();
                data['id'] = q.id;
                return data;
             }).toList();

          // Append Pages to PDF
          switch (anexo) {
            case 'I':
              if (autoEval != null) {
                  await pdfService.buildAnexoI(pdf, employee, autoEval, filteredQuestions, _selectedYear, president: president);
              }
              break;
            case 'II':
              if (gestorEval != null) {
                  await pdfService.buildAnexoII(pdf, employee, gestorEval, filteredQuestions, _selectedYear, president: president);
              }
              break;
            case 'III':
              if (autoEval != null && gestorEval != null) {
                  await pdfService.buildAnexoIII(pdf, employee, autoEval, gestorEval, filteredQuestions, _selectedYear, president: president);
              }
              break;
            case 'IV':
               if (autoEval != null) {
                  await pdfService.buildAnexoIV(pdf, employee, autoEval, filteredQuestions, _selectedYear, president: president);
               }
              break;
            case 'V':
              if (gestorEval != null) {
                  await pdfService.buildAnexoV(pdf, employee, gestorEval, filteredQuestions, _selectedYear, president: president);
              }
              break;
            case 'VI':
              if (autoEval != null && gestorEval != null) {
                  await pdfService.buildAnexoVI(pdf, employee, autoEval, gestorEval, filteredQuestions, _selectedYear, president: president);
              }
              break;
          }
        }
      }

      // Close Progress
      if (mounted) Navigator.of(context).pop();

      // Print
      final bytes = await pdf.save();
      final fileName = 'Relatorio_Massa_${DateTime.now().millisecondsSinceEpoch}.pdf';

      try {
        if (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
            await Printing.sharePdf(bytes: bytes, filename: fileName);
        } else {
            await Printing.layoutPdf(
              onLayout: (_) => Future.value(bytes),
              name: fileName,
            );
        }
      } catch (printError) {
         if (mounted) {
             showDialog(
               context: context,
               builder: (context) => AlertDialog(
                 title: const Text('Erro na Impressão'),
                 content: const Text('Erro ao conectar com a impressora. Deseja compartilhar o arquivo?'),
                 actions: [
                   TextButton(
                     onPressed: () => Navigator.pop(context),
                     child: const Text('Cancelar'),
                   ),
                   ElevatedButton(
                     onPressed: () {
                       Navigator.pop(context);
                       Printing.sharePdf(bytes: bytes, filename: fileName);
                     },
                     child: const Text('Compartilhar'),
                   ),
                 ],
               ),
             );
         }
      }

    } catch (e) {
      if (mounted) {
         Navigator.of(context).pop(); // Close dialog
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na geração em massa: $e'), backgroundColor: Colors.red),
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
                const SizedBox(height: 12),
                // Filters Row (Situation & Type)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Situacao filter
                    Expanded(
                      child: FutureBuilder<List<String>>(
                        future: _getAvailableSituacoes(),
                        builder: (context, snapshot) {
                          final situacoes = snapshot.data ?? [];
                          if (situacoes.isEmpty) return const SizedBox.shrink();
                          
                          return ExpandableFilterSection(
                            title: 'Filtrar por Situação',
                            count: _filtrosSituacao.length,
                            child: MultiSituacaoFilter(
                              selectedSituacoes: _filtrosSituacao,
                              availableSituacoes: situacoes.toSet(),
                              onChanged: (newSelection) {
                                setState(() {
                                  _filtrosSituacao = newSelection;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Type Filter
                    Expanded(
                      child: FutureBuilder<List<String>>(
                        future: _getAvailableTipos(),
                        builder: (context, snapshot) {
                          final tipos = snapshot.data ?? [];
                          if (tipos.isEmpty) return const SizedBox.shrink();

                          return ExpandableFilterSection(
                            title: 'Filtrar por Tipo',
                            count: _filtrosTipo.length,
                            child: MultiTipoFilter(
                              selectedTipos: _filtrosTipo,
                              availableTipos: tipos.toSet(),
                              onChanged: (newSelection) {
                                setState(() {
                                  _filtrosTipo = newSelection;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Keep selection checkbox
                CheckboxListTile(
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
              ],
            ),
              ],
            ),
          ),
          
          // BULK SELECTION BAR (Anexos)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleção para Impressão em Massa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['I', 'II', 'III', 'IV', 'V', 'VI'].map((anexo) {
                     final isSelected = _selectedAnexos.contains(anexo);
                     // Check if disabled (mutually exclusive)
                     final bool isOperacional = ['I', 'II', 'III'].contains(anexo);
                     final bool hasGerencialSelected = _selectedAnexos.any((a) => ['IV', 'V', 'VI'].contains(a));
                     final bool hasOperacionalSelected = _selectedAnexos.any((a) => ['I', 'II', 'III'].contains(a));
                     
                     bool disabled = false;
                     if (isOperacional && hasGerencialSelected) disabled = true;
                     if (!isOperacional && hasOperacionalSelected) disabled = true;

                     return FilterChip(
                       label: Text('Anexo $anexo'),
                       selected: isSelected,
                       onSelected: disabled ? null : (val) => _toggleAnexo(anexo, val),
                       selectedColor: Colors.blue.shade100,
                       checkmarkColor: Colors.blue,
                     );
                  }).toList(),
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

                return Column(
                  children: [
                    // SELECT ALL BAR
                    Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                           Text('${employees.length} funcionários encontrados'),
                           const Spacer(),
                           TextButton.icon(
                             icon: Icon(_selectedEmployees.length == employees.length ? Icons.deselect : Icons.select_all),
                             label: Text(_selectedEmployees.length == employees.length ? 'Desmarcar Todos' : 'Selecionar Pág.'),
                             onPressed: () => _toggleAll(employees),
                           ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          return _buildEmployeeCard(employees[index]);
                        },
                      ),
                    ),
                    // BULK ACTION BAR (Bottom)
                    if (_selectedEmployees.isNotEmpty && _selectedAnexos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.shade50,
                        child: Row(
                          children: [
                             Text('${_selectedEmployees.length} pessoas x ${_selectedAnexos.length} anexos', style: const TextStyle(fontWeight: FontWeight.bold)),
                             const Spacer(),
                             ElevatedButton.icon(
                               icon: const Icon(Icons.print),
                               label: const Text('IMPRIMIR EM MASSA'),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.blue,
                                 foregroundColor: Colors.white,
                               ),
                               onPressed: () => _generateBulkPDF(employees), 
                             ),
                          ],
                        ),
                      ),
                  ],
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

    final isSelected = _selectedEmployees.contains(employeeData.chapa);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: isSelected ? Colors.blue.shade50 : null,
      shape: isSelected ? RoundedRectangleBorder(side: BorderSide(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(4)) : null,
      child: Padding(
        padding: const EdgeInsets.all(8), // Reduced padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SELECTION CHECKBOX
            Checkbox(
              value: isSelected,
              onChanged: (val) => _toggleEmployee(employeeData.chapa, val),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Content Logic matches previous Column content...
                   // But since I'm replacing the whole card structure to insert Row -> Checkbox...
                   // I need to be careful to preserve the inner content.
                   // The original code had Column(Row(Expanded(Column...
                   // Let's reconstruct the inner part.
                   Padding(
                     padding: const EdgeInsets.only(left: 8, top: 8),
                     child: _buildEmployeeCardContent(employeeData, statusColor),
                   )
                ]
              )
            )
          ]
        ),
      ),
    );
  }

  Widget _buildEmployeeCardContent(EmployeeWithEvaluations employeeData, Color statusColor) {
     return Column(
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
                          Expanded(
                            child: Text(
                              employeeData.nome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis, // Prevent overflow
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

  Future<List<String>> _getAvailableTipos() async {
    try {
      final snapshot = await _firestore
          .collection('funcionarios')
          .where('ativo', isEqualTo: true)
          .get();

      final tipos = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tipo = data['codtipo']?.toString() ?? '';
        if (tipo.isNotEmpty) {
          tipos.add(tipo.toUpperCase());
        }
      }

      final list = tipos.toList()..sort();
      return list;
    } catch (e) {
      return [];
    }
  }
}
