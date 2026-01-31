import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/evaluation.dart';
import '../models/evaluation_type.dart';
import '../models/employee_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../utils/situacao_helper.dart';
import '../widgets/multi_situacao_filter.dart';

class CentralCiclosScreen extends StatefulWidget {
  final int currentCycleYear; // e.g., 2026

  const CentralCiclosScreen({super.key, required this.currentCycleYear});

  @override
  State<CentralCiclosScreen> createState() => _CentralCiclosScreenState();
}

class _CentralCiclosScreenState extends State<CentralCiclosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String? _filterStage; // '1' (Inicio), '2' (Meio), '3' (Fim), '4+' (Vencido)
  Set<String> _filtrosSituacao = {}; // 'A' (Ativo), 'I' (Inativo), 'F' (Falecido), 'P' (Pensionista), 'L' (Licença)
  
  final Set<String> _selectedEmployees = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Ciclos e Triênios'),
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
             icon: const Icon(Icons.upload_file),
             tooltip: 'Importar Histórico (CSV)',
             onPressed: _importCsv,
          ),
          if (_selectedEmployees.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(right: 16),
               child: Center(
                 child: Text(
                   '${_selectedEmployees.length} selecionados',
                   style: const TextStyle(fontWeight: FontWeight.bold),
                 ),
               ),
             )
        ],
      ),
      body: _isLoading 
        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Processando importação...')]))
        : Column(
        children: [
          // HEADER STATISTICS
          StreamBuilder<QuerySnapshot>(
             stream: _firestore.collection('funcionarios').snapshots(),
             builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                
                int total1 = 0;
                int total2 = 0;
                int total3 = 0;
                int totalExpired = 0;
                int totalNull = 0;
                
                // Coletar situações únicas
                final situacoesDisponiveis = <String>{};

                for (var doc in snapshot.data!.docs) {
                   final data = doc.data() as Map<String, dynamic>;
                   
                   // Coletar situação
                   final situacao = data['situacao']?.toString() ?? '';
                   if (situacao.isNotEmpty) {
                     situacoesDisponiveis.add(situacao.toUpperCase());
                   }

                   final start = data['currentTrienniumStart'] as int?;
                   if (start == null) {
                     totalNull++;
                     continue;
                   }

                   final delta = widget.currentCycleYear - start;
                   if (delta == 0) total1++;
                   if (delta == 1) total2++;
                   if (delta == 2) total3++;
                   if (delta > 2) totalExpired++;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.teal.shade50,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                           _buildStatBadge('Ano 1 (Início)', total1, Colors.green),
                           _buildStatBadge('Ano 2 (Meio)', total2, Colors.blue),
                           _buildStatBadge('Ano 3 (Final)', total3, Colors.orange),
                           _buildStatBadge('Renovação', totalExpired, Colors.red),
                        ],
                      ),
                      if (situacoesDisponiveis.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        MultiSituacaoFilter(
                          selectedSituacoes: _filtrosSituacao,
                          availableSituacoes: situacoesDisponiveis,
                          onChanged: (newSelection) {
                            setState(() {
                              _filtrosSituacao = newSelection;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                );
             },
          ),
          
          // FILTERS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
               children: [
                  Expanded(
                    child: TextField(
                       controller: _searchController,
                       decoration: const InputDecoration(
                          labelText: 'Buscar por Nome ou Matrícula',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                       ),
                       onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                     value: _filterStage,
                     hint: const Text('Filtrar Fase'),
                     underline: Container(),
                     icon: const Icon(Icons.filter_list),
                     items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(value: '0', child: Text('Ano 1 (Início)')),
                        DropdownMenuItem(value: '1', child: Text('Ano 2 (Meio)')),
                        DropdownMenuItem(value: '2', child: Text('Ano 3 (Fim)')),
                        DropdownMenuItem(value: 'expired', child: Text('Vencidos (>3)')),
                        DropdownMenuItem(value: 'null', child: Text('Sem Triênio')),
                     ],
                     onChanged: (v) => setState(() => _filterStage = v),
                  )
               ],
            ),
          ),
          
          if (_selectedEmployees.isNotEmpty)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(8),
               color: Colors.yellow.shade100,
               child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('DEFINIR INÍCIO DO TRIÊNIO EM MASSA'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _showBatchUpdateDialog,
               ),
             ),

          // LIST
          Expanded(
             child: StreamBuilder<QuerySnapshot>(
               stream: _firestore
                   .collection('funcionarios')
                   .snapshots(),
               builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Erro ao carregar'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final allDocs = snapshot.data!.docs;
                  
                  // Filter locally for simplicity with search/stage logic
                  final filtered = allDocs.where((doc) {
                     final data = doc.data() as Map<String, dynamic>;
                     final emp = Employee.fromFirestore(data, documentId: doc.id);
                     
                     // Search
                     final matchesSearch = emp.nome.toLowerCase().contains(_searchQuery) ||
                                           emp.id.contains(_searchQuery);
                     if (!matchesSearch) return false;

                     // Situacao Filter (multi-selection)
                     if (_filtrosSituacao.isNotEmpty) {
                        if (!_filtrosSituacao.contains(data['situacao'])) return false;
                     }

                     // Stage Filter
                     if (_filterStage != null) {
                        final start = emp.currentTrienniumStart;
                        if (_filterStage == 'null') return start == null;
                        if (start == null) return false; // If filtering by specific stage, exclude nulls

                        final delta = widget.currentCycleYear - start;
                        if (_filterStage == 'expired') return delta > 2;
                        return delta.toString() == _filterStage;
                     }

                     return true;
                  }).toList();
                  
                  // Sort: Expired first, then Null, then Normal
                  filtered.sort((a, b) {
                     final dataA = a.data() as Map<String, dynamic>;
                     final dataB = b.data() as Map<String, dynamic>;
                     final startA = dataA['currentTrienniumStart'] as int?;
                     final startB = dataB['currentTrienniumStart'] as int?;
                     
                     if (startA == null) return -1;
                     if (startB == null) return 1;
                     return startA.compareTo(startB);
                  });

                  return ListView.builder(
                     itemCount: filtered.length,
                     padding: const EdgeInsets.only(bottom: 80),
                     itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final emp = Employee.fromFirestore(doc.data() as Map<String, dynamic>, documentId: doc.id);
                        final isSelected = _selectedEmployees.contains(emp.id);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: isSelected ? Colors.teal.shade50 : null,
                          shape: isSelected 
                            ? RoundedRectangleBorder(side: const BorderSide(color: Colors.teal, width: 2), borderRadius: BorderRadius.circular(4)) 
                            : null,
                          child: InkWell(
                            onTap: () {
                               setState(() {
                                 if (isSelected) _selectedEmployees.remove(emp.id);
                                 else _selectedEmployees.add(emp.id);
                               });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                   Checkbox(
                                     value: isSelected,
                                     onChanged: (v) {
                                       setState(() {
                                          if (v == true) _selectedEmployees.add(emp.id);
                                          else _selectedEmployees.remove(emp.id);
                                       });
                                     },
                                   ),
                                   CircleAvatar(
                                     backgroundColor: Colors.grey.shade200,
                                     child: Text(emp.nome.substring(0,1)),
                                   ),
                                   const SizedBox(width: 12),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                          Text(emp.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Mat: ${emp.id} - ${emp.funcao}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                       ]
                                     )
                                   ),
                                   _buildStageInfo(emp.currentTrienniumStart),
                                ],
                              ),
                            ),
                          ),
                        );
                     },
                  );
               },
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
     return Column(
       children: [
         Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
         Text(label, style: const TextStyle(fontSize: 10)),
       ],
     );
  }

  Widget _buildStageInfo(int? startYear) {
     if (startYear == null) {
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
         decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4)),
         child: const Text('Não Definido', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
       );
     }

     final delta = widget.currentCycleYear - startYear;
     Color color = Colors.grey;
     String text = '';

     if (delta == 0) { color = Colors.green; text = 'Ano 1 (Início)'; }
     else if (delta == 1) { color = Colors.blue; text = 'Ano 2 (Meio)'; }
     else if (delta == 2) { color = Colors.orange; text = 'Ano 3 (Fim)'; }
     else if (delta > 2) { color = Colors.red; text = 'Vencido (Reno.)'; }
     else { color = Colors.purple; text = 'Futuro?'; } // Should not happen usually

     return Column(
       crossAxisAlignment: CrossAxisAlignment.end,
       children: [
         Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
         ),
         const SizedBox(height: 2),
         Text('Início: $startYear', style: const TextStyle(fontSize: 9, color: Colors.grey)),
       ],
     );
  }

  Future<void> _showBatchUpdateDialog() async {
     final controller = TextEditingController(text: widget.currentCycleYear.toString());
     
     final confirm = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Atualizar ${_selectedEmployees.length} Funcionários'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('Defina o novo ANO DE INÍCIO do Triênio para os selecionados.'),
             const SizedBox(height: 10),
             TextField(
               controller: controller,
               keyboardType: TextInputType.number,
               decoration: const InputDecoration(
                 labelText: 'Ano de Início (ex: 2026)',
                 border: OutlineInputBorder(),
               ),
             ),
             const SizedBox(height: 10),
             const Text('Nota: Se definir 2026 e estamos em 2026, será considerado Ano 1.', style: TextStyle(fontSize: 12, color: Colors.grey)),
           ],
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
           ElevatedButton(
             onPressed: () => Navigator.pop(context, true),
             child: const Text('Confirmar Atualização'),
           ),
         ],
       ),
     );

     if (confirm == true && controller.text.isNotEmpty) {
        final newStart = int.tryParse(controller.text);
        if (newStart != null) {
           await _performBatchUpdate(newStart);
        }
     }
  }

  Future<void> _performBatchUpdate(int newStartYear) async {
    setState(() => _isLoading = true);
    final batch = _firestore.batch();
    
    for (var id in _selectedEmployees) {
       final ref = _firestore.collection('funcionarios').doc(id);
       batch.update(ref, {'currentTrienniumStart': newStartYear});
    }

    await batch.commit();

    setState(() {
      _isLoading = false;
      _selectedEmployees.clear(); // Clear selection after update
    });

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Triênio atualizado para $newStartYear com sucesso!')),
       );
    }
  }

  Future<void> _importCsv() async {
    // 1. Pick File
    final result = await FilePicker.platform.pickFiles(
       type: FileType.custom,
       allowedExtensions: ['csv', 'txt'],
       withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    
    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;

    // 2. Ask for "Cohort Start Year" (e.g., 2024 for the 2024/25/26 cycle)
    final yearController = TextEditingController(text: '2024');
    final startYear = await showDialog<int>(
       context: context,
       builder: (context) => AlertDialog(
          title: const Text('Importação de Histórico'),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                const Text('Este arquivo contém dados de qual CICLO/COHORT?'),
                const SizedBox(height: 16),
                TextField(
                   controller: yearController,
                   keyboardType: TextInputType.number,
                   decoration: const InputDecoration(
                      labelText: 'Ano de Início do Triênio (ex: 2024)',
                      hintText: 'Define que estes funcionários começaram em 2024',
                      border: OutlineInputBorder(),
                   ),
                ),
                const SizedBox(height: 8),
                const Text('Isso definirá o "Ano 1" para todos os funcionários do arquivo.', style: TextStyle(fontSize: 12, color: Colors.grey)),
             ],
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
             ElevatedButton(
                onPressed: () => Navigator.pop(context, int.tryParse(yearController.text)),
                child: const Text('Processar Importação'),
             ),
          ],
       ),
    );

    if (startYear == null) return;

    setState(() => _isLoading = true);

    try {
     // Try UTF-8 first, fallback to Latin1 (Windows CSV default)
     String content;
     try {
       content = utf8.decode(fileBytes);
     } catch (e) {
       content = latin1.decode(fileBytes);
     }
     final lines = const LineSplitter().convert(content);
       
       if (lines.isEmpty) throw 'Arquivo vazio';

       // Header check
       final header = lines.first.toUpperCase().split(';');
       // Expected: CHAPA;...
       final chapaIdx = header.indexOf('CHAPA');
       final nota24Idx = header.indexWhere((h) => h.contains('2024') || h.contains('NOTA_2024'));
       final nota25Idx = header.indexWhere((h) => h.contains('2025') || h.contains('NOTA_2025'));

       if (chapaIdx == -1) throw 'Coluna CHAPA não encontrada';

       final batch = _firestore.batch();
       int count = 0;

       // Cache valid employees to avoid errors
       final allEmps = await _firestore.collection('funcionarios').get();
       final empMap = {for (var e in allEmps.docs) e.id: e.data()};

       for (var i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          final row = lines[i].split(';');
          if (row.length <= chapaIdx) continue;

          final chapa = row[chapaIdx].trim();
          if (!empMap.containsKey(chapa)) continue; // Skip unknown chapa

          // 1. Update Cohort Year
          final empRef = _firestore.collection('funcionarios').doc(chapa);
          batch.update(empRef, {'currentTrienniumStart': startYear});

          // 2. Process Note 2024
          if (nota24Idx != -1 && row.length > nota24Idx) {
             final val = row[nota24Idx].trim();
             if (val.isNotEmpty) {
                _addEvaluationToBatch(batch, chapa, 2024, val, empMap[chapa]!);
             }
          }

          // 3. Process Note 2025
          if (nota25Idx != -1 && row.length > nota25Idx) {
             final val = row[nota25Idx].trim();
             if (val.isNotEmpty) {
                 _addEvaluationToBatch(batch, chapa, 2025, val, empMap[chapa]!);
             }
          }
          
          count++;
          if (count % 400 == 0) { // Batch limit 500
             await batch.commit();
          }
       }

       await batch.commit();

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Importação concluída! $count registros processados.')),
         );
       }

    } catch (e) {
       if (mounted) {
         showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Erro'), content: Text(e.toString())));
       }
    } finally {
       setState(() => _isLoading = false);
    }
  }

  void _addEvaluationToBatch(WriteBatch batch, String chapa, int year, String rawValue, Map<String, dynamic> empData) {
     final empSnapshot = EmployeeSnapshot.fromMap({
        'id': empData['id'] ?? empData['chapa'],
        'nome': empData['nome'],
        'funcao': empData['funcao'],
     });
     
     final docId = Evaluation.generateId(year, chapa, EvaluationType.finalOperacional); // Assuming Historical is Final
     final ref = _firestore.collection('evaluations').doc(docId);

     double? manualScore;
     String? specialStatus;

     // Parse value
     // Try double (replace , with .)
     final cleanVal = rawValue.replaceAll(',', '.');
     final score = double.tryParse(cleanVal);

     if (score != null) {
        manualScore = score;
     } else {
        specialStatus = rawValue; // "Afastamento", etc.
     }

     final eval = Evaluation(
        id: docId,
        year: year,
        type: EvaluationType.finalOperacional, // Historical data is treated as Final Result
        answers: {}, // Empty, overridden by manual/special
        employeeSnapshot: empSnapshot,
        manualScore: manualScore,
        specialStatus: specialStatus,
        obs: 'Importado via CSV (Histórico)',
     );

     batch.set(ref, eval.toFirestore(), SetOptions(merge: true));
  }
}



