import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../../models/employee_with_evaluations.dart';
import '../../services/pdf_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/situacao_helper.dart';
import '../../utils/tipo_funcionario_helper.dart';
import '../../widgets/multi_situacao_filter.dart';
import '../../widgets/multi_tipo_filter.dart';
import '../../widgets/expandable_filter_section.dart';
import '../../models/commission_president.dart';
import '../central_impressao_screen.dart';

class TabImpressoesAvaliacao extends StatefulWidget {
  const TabImpressoesAvaliacao({super.key});

  @override
  State<TabImpressoesAvaliacao> createState() => _TabImpressoesAvaliacaoState();
}

class _TabImpressoesAvaliacaoState extends State<TabImpressoesAvaliacao> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _statusFilter = 'Todos'; // New Filter
  Set<String> _filtrosSituacao = {};
  Set<String> _filtrosTipo = {};
  int _selectedYear = DateTime.now().year;
  bool _keepSelection = false;
  
  // Bulk Selection State
  final Set<String> _selectedAnexos = {}; 
  final Set<String> _selectedEmployees = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleAnexo(String key, bool selected) {
    setState(() {
      if (selected) {
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

  Future<List<String>> _getAvailableSituacoes() async {
     try {
       final snapshot = await _firestore.collection('funcionarios').get();
       final situacoes = <String>{};
       for (var doc in snapshot.docs) {
         final data = doc.data();
         if (data['situacao'] != null) {
           situacoes.add(data['situacao'].toString().toUpperCase());
         }
       }
       return situacoes.toList()..sort();
     } catch (e) {
       return [];
     }
  }

  Future<List<String>> _getAvailableTipos() async {
     try {
       final snapshot = await _firestore.collection('funcionarios').get();
       final tipos = <String>{};
       for (var doc in snapshot.docs) {
         final data = doc.data();
         if (data['codtipo'] != null) {
           tipos.add(data['codtipo'].toString().toUpperCase());
         }
       }
       return tipos.toList()..sort();
     } catch (e) {
       return [];
     }
  }

  Future<List<EmployeeWithEvaluations>> _getEmployeesWithEvaluations() async {
    final employeesSnapshot = await _firestore.collection('funcionarios').get();
    
    final yearStr = _selectedYear.toString();
    
    final evaluationsSnapshot = await _firestore
        .collection('evaluations')
        .where('ano', isEqualTo: yearStr)
        .get();

    final Map<String, Map<String, dynamic>> evaluationsMap = {};
    for (var doc in evaluationsSnapshot.docs) {
      evaluationsMap[doc.id] = doc.data();
    }
    
    final List<EmployeeWithEvaluations> result = [];

    for (final doc in employeesSnapshot.docs) {
      final data = doc.data();
      final chapa = doc.id;

      if (_searchQuery.isNotEmpty) {
        final nome = (data['nome']?.toString() ?? '').toLowerCase();
        final chapaLower = chapa.toLowerCase();
        if (!nome.contains(_searchQuery) && !chapaLower.contains(_searchQuery)) {
          continue;
        }
      }

      if (_filtrosSituacao.isNotEmpty) {
        final situacao = data['situacao']?.toString() ?? '';
        if (!_filtrosSituacao.contains(situacao.toUpperCase())) {
          continue;
        }
      }
      
      if (_filtrosTipo.isNotEmpty) {
        final tipo = data['codtipo']?.toString() ?? '';
        if (!_filtrosTipo.contains(tipo.toUpperCase())) {
          continue;
        }
      }

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

      // Status Filter Logic
      if (_statusFilter != 'Todos') {
         bool matchStatus = false;
         final bool hasPendingDisciplinary = (gestorData != null && 
             (gestorData['status'] == 'aguardando_comissao' || 
              (gestorData['pdfData'] != null && gestorData['pdfData']['ocorrenciaDisciplinar'] == true && gestorData['status'] != 'concluida')
             ));

         if (_statusFilter == 'aguardando_comissao') {
            if (hasPendingDisciplinary) matchStatus = true;
         } else if (_statusFilter == 'concluida') {
            if (gestorData != null && gestorData['status'] == 'concluida' && !hasPendingDisciplinary) matchStatus = true;
         } else if (_statusFilter == 'pendente') {
            if (gestorData == null || (gestorData['status'] != 'concluida' && !hasPendingDisciplinary)) matchStatus = true;
         }
         
         if (!matchStatus) continue;
      }

      if (_selectedAnexos.isNotEmpty) {
        bool match = false;
        if (!employeeWithEval.isManager) {
           if (_selectedAnexos.contains('I') && employeeWithEval.autoEvaluation != null) match = true;
           if (_selectedAnexos.contains('II') && employeeWithEval.gestorEvaluation != null) match = true;
           if (_selectedAnexos.contains('III') && employeeWithEval.hasAnyEvaluation) match = true;
        } 
        if (employeeWithEval.isManager) { 
           if (_selectedAnexos.contains('IV') && employeeWithEval.autoEvaluation != null) match = true;
           if (_selectedAnexos.contains('V') && employeeWithEval.gestorEvaluation != null) match = true;
           if (_selectedAnexos.contains('VI') && employeeWithEval.hasAnyEvaluation) match = true;
        }
        if (!match) continue;
      }

      if (employeeWithEval.hasAnyEvaluation) {
        result.add(employeeWithEval);
      }
    }

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
        
        if (name == 'Presidente da Comissão' || name.isEmpty) {
           try {
             var userDoc = await _firestore.collection('funcionarios').doc(doc.id).get();
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
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final employee = await _firebaseService.getEmployeeById(employeeData.chapa);
      if (employee == null) throw Exception('Funcionário não encontrado');

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

      final autoEval = employeeData.autoEvaluation != null 
          ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_AUTO')
          : null;
      final gestorEval = employeeData.gestorEvaluation != null
          ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_GESTOR')
          : null;

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

      if (mounted) Navigator.pop(context);

      if (mounted) {
        try {
           if (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
               await Printing.sharePdf(bytes: pdfBytes, filename: 'Relatorio_${employeeData.chapa}_$anexoType.pdf');
           } else {
               await Printing.layoutPdf(
                 onLayout: (_) => Future.value(pdfBytes),
                 name: 'Relatorio_${employeeData.chapa}_$anexoType.pdf',
               );
           }
        } catch (printError) {
           if (mounted) {
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
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
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
    final selectedList = allEmployees.where((e) => _selectedEmployees.contains(e.chapa)).toList();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
           title: Text('Gerando Relatórios...'),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               LinearProgressIndicator(),
               SizedBox(height: 10),
               Text('Processando documentação... Aguarde.'),
             ],
           ),
        );
      }
    );

    try {
      final pdfService = PdfService();
      final president = await _getCommissionPresident();
      final pdf = pw.Document();
      final allQuestions = await _firebaseService.getQuestions();

      for (var employeeData in selectedList) {
        await Future.delayed(Duration.zero);
        final employee = await _firebaseService.getEmployeeById(employeeData.chapa);
        if (employee == null) continue;

        final autoEval = employeeData.autoEvaluation != null 
             ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_AUTO')
             : null;
        final gestorEval = employeeData.gestorEvaluation != null
             ? await _firebaseService.getEvaluation('${_selectedYear}_${employeeData.chapa}_GESTOR')
             : null;

        for (var anexo in _selectedAnexos) {
          String roleType = 'OPERACIONAL';
          if (['IV', 'V', 'VI'].contains(anexo)) roleType = 'GERENCIAL';
          
          final filteredQuestions = allQuestions
             .where((q) => q.tipo == roleType && q.ativo)
             .map((q) {
                final data = q.toFirestore();
                data['id'] = q.id;
                return data;
             }).toList();

          switch (anexo) {
            case 'I':
              if (autoEval != null) await pdfService.buildAnexoI(pdf, employee, autoEval, filteredQuestions, _selectedYear, president: president);
              break;
            case 'II':
              if (gestorEval != null) await pdfService.buildAnexoII(pdf, employee, gestorEval, filteredQuestions, _selectedYear, president: president);
              break;
            case 'III':
              if (autoEval != null && gestorEval != null) await pdfService.buildAnexoIII(pdf, employee, autoEval, gestorEval, filteredQuestions, _selectedYear, president: president);
              break;
            case 'IV':
               if (autoEval != null) await pdfService.buildAnexoIV(pdf, employee, autoEval, filteredQuestions, _selectedYear, president: president);
              break;
            case 'V':
              if (gestorEval != null) await pdfService.buildAnexoV(pdf, employee, gestorEval, filteredQuestions, _selectedYear, president: president);
              break;
            case 'VI':
              if (autoEval != null && gestorEval != null) await pdfService.buildAnexoVI(pdf, employee, autoEval, gestorEval, filteredQuestions, _selectedYear, president: president);
              break;
          }
        }
      }

      if (mounted) Navigator.of(context).pop();

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
             Printing.sharePdf(bytes: bytes, filename: fileName);
         }
      }

    } catch (e) {
      if (mounted) {
         Navigator.of(context).pop(); 
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na geração em massa: $e'), backgroundColor: Colors.red),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem(value: year, child: Text(year.toString()));
                      }),
                      onChanged: (value) => setState(() => _selectedYear = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Buscar por Nome ou Chapa',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; })) : null,
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Status Filter
              Row(
                children: [
                   Expanded(
                     child: DropdownButtonFormField<String>(
                       value: _statusFilter,
                       decoration: const InputDecoration(
                         labelText: 'Status Avaliação',
                         border: OutlineInputBorder(),
                         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       ),
                       items: const [
                          DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                          DropdownMenuItem(value: 'aguardando_comissao', child: Text('❗ Aguardando Comissão', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'concluida', child: Text('Concluída')),
                          DropdownMenuItem(value: 'pendente', child: Text('Em Andamento')),
                       ],
                       onChanged: (val) {
                          if (val != null) setState(() => _statusFilter = val);
                       },
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            onChanged: (newSelection) => setState(() => _filtrosSituacao = newSelection),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            onChanged: (newSelection) => setState(() => _filtrosTipo = newSelection),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Manter seleção ao imprimir'),
                value: _keepSelection,
                onChanged: (value) => setState(() => _keepSelection = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        
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
        
        Expanded(
          child: FutureBuilder<List<EmployeeWithEvaluations>>(
            future: _getEmployeesWithEvaluations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
              
              final employees = snapshot.data ?? [];
              if (employees.isEmpty) return const Center(child: Text('Nenhuma avaliação encontrada'));

              return Column(
                children: [
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
                      itemBuilder: (context, index) => _buildEmployeeCard(employees[index]),
                    ),
                  ),
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
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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
      shape: isSelected ? RoundedRectangleBorder(side: const BorderSide(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(4)) : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (val) => _toggleEmployee(employeeData.chapa, val),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${employeeData.nome} (${employeeData.chapa})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          if (employeeData.gestorEvaluation != null && 
                              (employeeData.gestorEvaluation?['status'] == 'aguardando_comissao' || 
                               (employeeData.gestorEvaluation?['pdfData'] != null && 
                                employeeData.gestorEvaluation?['pdfData']['ocorrenciaDisciplinar'] == true &&
                                employeeData.gestorEvaluation?['status'] != 'concluida')))
                                   Padding(
                                     padding: const EdgeInsets.only(right: 8.0),
                                     child: IconButton(
                                       icon: const Icon(Icons.flag, color: Colors.red),
                                       tooltip: 'Resolver Ocorrência Disciplinar',
                                       onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CentralImpressaoScreen(
                                                initialIndex: 1, 
                                                initialSearch: employeeData.chapa,
                                              ),
                                            ),
                                          );
                                       },
                                     ),
                                   ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              employeeData.statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(employeeData.funcao),
                      const SizedBox(height: 8),
                      // Action Chips
                      Wrap(
                        spacing: 8,
                        children: [
                          if (!employeeData.isManager) ...[
                             if (employeeData.autoEvaluation != null)
                               ActionChip(
                                 label: const Text('Anexo I (Auto)'),
                                 avatar: const Icon(Icons.print, size: 16),
                                 onPressed: () => _generatePDF(employeeData, 'I'),
                               ),
                             if (employeeData.gestorEvaluation != null)
                               ActionChip(
                                 label: const Text('Anexo II (Gestor)'),
                                 avatar: const Icon(Icons.print, size: 16),
                                 onPressed: () => _generatePDF(employeeData, 'II'),
                               ),
                             if (employeeData.hasAnyEvaluation)
                               ActionChip(
                                 label: const Text('Anexo III (Consenso)'),
                                 avatar: const Icon(Icons.print, size: 16),
                                 onPressed: () => _generatePDF(employeeData, 'III'),
                               ),
                          ],
                          if (employeeData.isManager) ...[
                             if (employeeData.autoEvaluation != null)
                               ActionChip(
                                 label: const Text('Anexo IV (Gestor Auto)'),
                                 avatar: const Icon(Icons.print, size: 16),
                                 onPressed: () => _generatePDF(employeeData, 'IV'),
                               ),
                             if (employeeData.gestorEvaluation != null)
                               ActionChip(
                                 label: const Text('Anexo V (Comitê)'),
                                 avatar: const Icon(Icons.print, size: 16),
                                 onPressed: () => _generatePDF(employeeData, 'V'),
                               ),
                             if (employeeData.hasAnyEvaluation)
                               ActionChip(
                                 label: const Text('Anexo VI (Consenso)'),
                                 avatar: const Icon(Icons.print, size: 16),
                                 onPressed: () => _generatePDF(employeeData, 'VI'),
                               ),
                          ],
                        ]
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
