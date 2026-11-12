import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:printing/printing.dart';

import 'package:flutter/foundation.dart'; // for kIsWeb

import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;



import '../../models/employee.dart';

import '../../models/evaluation.dart';

import '../../models/commission_president.dart';

import '../../services/pdf_service.dart';
import '../../services/excel_rh_service.dart';
import '../../utils/progressao_helper.dart';
import 'package:file_saver/file_saver.dart';

import '../../utils/situacao_helper.dart';

import '../../utils/tipo_funcionario_helper.dart';

import '../../widgets/multi_situacao_filter.dart';

import '../../widgets/multi_tipo_filter.dart';

import '../../widgets/expandable_filter_section.dart';



class TabEncerramentoCiclo extends StatefulWidget {
  final String? initialSearch;
  const TabEncerramentoCiclo({super.key, this.initialSearch});

  @override
  State<TabEncerramentoCiclo> createState() => _TabEncerramentoCicloState();
}



class _TabEncerramentoCicloState extends State<TabEncerramentoCiclo> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final PdfService _pdfService = PdfService();



  // State

  bool _isLoading = false;

  List<EmployeeCycleData> _allEmployeesData = [];
  List<Evaluation> _allEvaluations = [];

  List<EmployeeCycleData> _filteredEmployeesData = [];

  

  // Filters

  String _searchQuery = '';

  Set<String> _filtrosSituacao = {};

  Set<String> _filtrosTipo = {};

  Set<String> _filtrosMedia = {}; // 'High', 'Med', 'Low', 'Critical'
  
  Set<String> _filtrosStatus = {}; // 'PENDENTE', 'CONCLUIDA'

  int _referenceYear = DateTime.now().year;



  // Batch Config

  final TextEditingController _resultTextController = TextEditingController();

  int? _selectedRecommendationIndex;

  final Set<String> _selectedChapas = {};

  

  // Cache

  List<String> _availableSituacoes = [];

  List<String> _availableTipos = [];



  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) {
      _searchQuery = widget.initialSearch!.toLowerCase();
    }
    _loadInitialData();
  }



  Future<void> _loadInitialData() async {

    setState(() => _isLoading = true);

    

    // Load Helper Data

    final employeesSnap = await _firestore.collection('funcionarios').get();

    final situacoes = <String>{};

    final tipos = <String>{};

    

    for (var doc in employeesSnap.docs) {

      final data = doc.data();

      if (data['situacao'] != null) situacoes.add(data['situacao'].toString().toUpperCase());

      if (data['codtipo'] != null) tipos.add(data['codtipo'].toString().toUpperCase());

    }

    

    _availableSituacoes = situacoes.toList()..sort();

    _availableTipos = tipos.toList()..sort();



    await _loadCycleData();

  }



  Future<void> _loadCycleData() async {

    setState(() => _isLoading = true);



    try {

      // 1. Fetch Employees

      final employeesSnap = await _firestore.collection('funcionarios').get();

      final employees = employeesSnap.docs.map((d) => Employee.fromFirestore(d.data())).toList();



      // 2. Fetch Evaluations for Reference Year and previous 2 years

      // Optimization: Fetch all needed years in parallel

      final yearsToFetch = [_referenceYear, _referenceYear - 1, _referenceYear - 2, _referenceYear - 3, _referenceYear - 4]; // Margin

      

      final List<Evaluation> allEvaluations = [];
      final Set<String> loadedDocIds = {};

      for (var year in yearsToFetch) {
        // Query by 'year' int field (old/imported evals)
        final snap1 = await _firestore.collection('evaluations').where('year', isEqualTo: year).get();
        // Query by 'ano' string field (evals saved by the app)
        final snap2 = await _firestore.collection('evaluations').where('ano', isEqualTo: year.toString()).get();
        // Query by 'ciclo' string field (alternate app format)
        final snap3 = await _firestore.collection('evaluations').where('ciclo', isEqualTo: year.toString()).get();

        for (final snap in [snap1, snap2, snap3]) {
          for (final d in snap.docs) {
            if (loadedDocIds.contains(d.id)) continue; // Deduplicate
            loadedDocIds.add(d.id);
            final data = d.data();
            data['id'] = d.id;
            // Ensure year is set correctly (some docs might not have 'year')
            data['year'] ??= year;
            allEvaluations.add(Evaluation.fromFirestore(data));
          }
        }
      }



      // 3. Process Data

      final List<EmployeeCycleData> processedData = [];



      for (var emp in employees) {

         final startYear = emp.currentTrienniumStart ?? (_referenceYear - 2);

         final cycleYears = [startYear, startYear + 1, startYear + 2];
         
         // Collect scores
         final Map<int, double?> scores = {};
         final List<Evaluation> empEvaluations = [];

         for (var year in cycleYears) {
            final r = _calcAno(allEvaluations, emp.id, year);
            scores[year] = r.score;
            if (r.best != null) empEvaluations.add(r.best!);
         }



         // Calc Average

         double sum = 0;

         int count = 0;

         scores.values.where((v) => v != null).forEach((v) {

           sum += v!;

           count++;

         });

         final avg = count > 0 ? sum / count : 0.0;



         // Check for pending disciplinary
         bool pending = false;
         for (var ev in empEvaluations) {
            if (ev.status == 'aguardando_comissao') {
               pending = true;
               break;
            }
            // Also check pdfData just in case status wasn't updated but flag is there (safety)
            if (ev.pdfData != null && ev.pdfData!['ocorrenciaDisciplinar'] == true && ev.status != 'concluida') {
               pending = true;
            }
         }

         processedData.add(EmployeeCycleData(
           employee: emp,
           average: avg,
           scores: scores,
           cycleYears: cycleYears,
           evaluations: empEvaluations,
           hasPendingDisciplinary: pending,
         ));

      }



      _allEvaluations = allEvaluations;
      _allEmployeesData = processedData;

      _applyFilters();



    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));

    } finally {

      setState(() => _isLoading = false);

    }

  }



  /// Nota de um funcionário em um ano (mesma regra da tela e do Excel do RH):
  /// nota manual, senão (total empregado + total gestor) / 2 como no Anexo III.
  /// [disciplinar] é verdadeiro se alguma avaliação do ano tem ocorrência
  /// disciplinar marcada (pendente ou já confirmada pela comissão).
  ({double? score, Evaluation? best, bool disciplinar}) _calcAno(
      List<Evaluation> allEvaluations, String empId, int year) {
    final yearlyEvals = allEvaluations.where((e) {
      final parts = e.id.split('_');
      if (parts.length < 2) return false;
      return parts[1] == empId && e.year == year;
    }).toList();

    final disciplinar = yearlyEvals
        .any((e) => e.pdfData != null && e.pdfData!['ocorrenciaDisciplinar'] == true);

    double? score;
    Evaluation? bestEval;

    if (yearlyEvals.isNotEmpty) {
      final manual = yearlyEvals.where((e) => e.manualScore != null).firstOrNull;
      if (manual != null) {
        score = manual.manualScore;
        bestEval = manual;
      } else {
        final autoEval = yearlyEvals.where((e) => e.id.contains('_AUTO')).firstOrNull;
        final gestorEval = yearlyEvals.where((e) => e.id.contains('_GESTOR')).firstOrNull;

        double autoTotal = 0;
        if (autoEval != null) {
          autoEval.answers.forEach((k, v) => autoTotal += v);
        }

        double gestorTotal = 0;
        if (gestorEval != null) {
          gestorEval.answers.forEach((k, v) => gestorTotal += v);
        }

        score = (autoTotal + gestorTotal) / 2;
        bestEval = gestorEval ?? autoEval;
      }
    }
    return (score: score, best: bestEval, disciplinar: disciplinar);
  }

  void _applyFilters() {

    setState(() {

      _filteredEmployeesData = _allEmployeesData.where((data) {

        // Search

        if (_searchQuery.isNotEmpty) {

           if (!data.employee.nome.toLowerCase().contains(_searchQuery) && !data.employee.id.contains(_searchQuery)) return false; 

        }



        // Situacao

        if (_filtrosSituacao.isNotEmpty && !_filtrosSituacao.contains(data.employee.situacao.toUpperCase())) return false;



        // Tipo
        final tipo = data.employee.codtipo?.toUpperCase() ?? '';
        if (_filtrosTipo.isNotEmpty && !_filtrosTipo.contains(tipo)) return false;

        // Status (PENDENCIA / CONCLUIDA)
        // PENDENTE = tem ocorrencia aguardando comissao
        // CONCLUIDA = tem avaliação com nota para o ano de referência E sem pendência disciplinar
        if (_filtrosStatus.isNotEmpty) {
           bool match = false;
           if (_filtrosStatus.contains('PENDENTE') && data.hasPendingDisciplinary) {
               match = true;
           }
           if (_filtrosStatus.contains('CONCLUIDA') && !data.hasPendingDisciplinary) {
               // Concluída = tem avaliação com nota para o ano corrente
               // (não requer status='concluida' explícito pois avaliações antigas não têm esse campo)
               final hasCurrentYearEval = data.evaluations.any((e) => e.year == _referenceYear);
               if (hasCurrentYearEval) {
                   match = true;
               }
           }
           if (!match) return false;
        }

        // Media Filter

        if (_filtrosMedia.isNotEmpty) {

           bool mediaMatch = false;

           if (_filtrosMedia.contains('High') && data.average >= 70) mediaMatch = true;

           if (_filtrosMedia.contains('Med') && data.average >= 50 && data.average < 70) mediaMatch = true;

           if (_filtrosMedia.contains('Low') && data.average >= 20 && data.average < 50) mediaMatch = true;

           if (_filtrosMedia.contains('Critical') && data.average < 20) mediaMatch = true;

           if (!mediaMatch) return false;

        }



        return true;

      }).toList();

      

      // Sort

      _filteredEmployeesData.sort((a, b) => a.employee.nome.compareTo(b.employee.nome));

    });

  }

  

  void _toggleAllFiltered() {

     final allIds = _filteredEmployeesData.map((e) => e.employee.id).toSet();

     final allSelected = allIds.every((id) => _selectedChapas.contains(id));

     

     setState(() {

       if (allSelected) {

         _selectedChapas.removeAll(allIds);

       } else {

         _selectedChapas.addAll(allIds);

       }

     });

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
        
        // LOGIC FROM ANEXO III/VI: Fetch real name if generic
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
            metadata: data['signatureMetadata'] ?? data['metadata'] ?? {},
          );
        }
      }
    } catch (e) {
      print('Erro ao buscar presidente: $e');
    }
    return null;
  }



  /// Exporta para o RH todos que fecham o triênio no ano de referência, com a
  /// coluna PROGRESSAO (sim/não) e MOTIVO. Direito à progressão (calculado na
  /// hora, nada é gravado):
  ///  1. o triênio fecha no ano de referência (pelo ano de admissão, base 2009);
  ///  2. as 3 notas do triênio são maiores que 70;
  ///  3. nenhuma avaliação do triênio tem ocorrência disciplinar.
  Future<void> _exportarExcelRH() async {
    final ref = _referenceYear;
    final anos = ProgressaoHelper.anosDoTrienio(ref);

    final linhas = <LinhaProgressaoRH>[];
    final semDireito = <String>[]; // "NOME (chapa): motivo"
    final avisos = <String>[];

    for (final d in _allEmployeesData) {
      final emp = d.employee;
      final admAno = ProgressaoHelper.anoAdmissao(emp.admissao);
      final rotulo = '${emp.nome} (${emp.id})';

      if (admAno == null) {
        avisos.add('$rotulo: sem data de admissão válida, não foi possível avaliar.');
        continue;
      }

      final fechaPorAdmissao = ProgressaoHelper.progressaoNoAno(admAno, ref);
      final start = emp.currentTrienniumStart;
      final fechaPorStart = start != null && start + 2 == ref;
      if (fechaPorAdmissao != fechaPorStart) {
        avisos.add(fechaPorAdmissao
            ? '$rotulo: pela admissão fecha o triênio em $ref, mas o início gravado é ${start ?? "vazio"}.'
            : '$rotulo: o início gravado ($start) fecha em $ref, mas pela admissão ($admAno) não.');
      }
      if (!fechaPorAdmissao) continue;

      final notas = <int, double>{};
      final motivos = <String>[];
      var disciplinar = false;
      for (final a in anos) {
        final r = _calcAno(_allEvaluations, emp.id, a);
        if (r.disciplinar) disciplinar = true;
        if (r.best == null || r.score == null) {
          motivos.add('sem nota em $a');
        } else {
          notas[a] = r.score!;
          if (r.score! <= ProgressaoHelper.notaMinima) {
            motivos.add('nota $a = ${r.score!.toStringAsFixed(1)}');
          }
        }
      }
      if (disciplinar) motivos.add('ocorrência disciplinar');

      final temDireito = motivos.isEmpty;
      linhas.add(LinhaProgressaoRH(
        chapa: emp.id,
        nome: emp.nome,
        admissao: emp.admissao,
        funcao: emp.funcao,
        nivel: emp.nivel,
        faixa: emp.faixa,
        situacao: emp.situacao,
        notas: notas,
        progressao: temDireito,
        motivo: motivos.join('; '),
      ));
      if (!temDireito) semDireito.add('$rotulo: ${motivos.join(", ")}');
    }

    linhas.sort((a, b) => a.nome.compareTo(b.nome));
    semDireito.sort();
    final comDireito = linhas.where((l) => l.progressao).length;
    avisos.sort();

    if (!mounted) return;
    final baixar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excel para o RH - triênio ${anos.first} a ${anos.last}'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${linhas.length} pessoa(s) fecham o triênio e vão na planilha: $comDireito com direito à progressão e ${semDireito.length} sem direito (com o motivo).',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Regra: triênio fecha em $ref (pelo ano de admissão), as 3 notas maiores que 70 e sem ocorrência disciplinar.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (semDireito.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Sem direito à progressão (${semDireito.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  for (final c in semDireito) Text('• $c', style: const TextStyle(fontSize: 12)),
                ],
                if (avisos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Atenção - dados divergentes (${avisos.length}):',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                  const SizedBox(height: 4),
                  for (final c in avisos) Text('• $c', style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: linhas.isEmpty ? null : () => Navigator.pop(ctx, true),
            child: const Text('Baixar Excel'),
          ),
        ],
      ),
    );
    if (baixar != true) return;

    final bytes = ExcelRhService.gerar(linhas, anos);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível gerar o Excel.')));
      }
      return;
    }
    await FileSaver.instance.saveFile(
      name: 'Progressao_RH_${anos.first}_${anos.last}',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> _generateBatchPDF() async {

    if (_selectedChapas.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum funcionário selecionado.')));

      return;

    }



    final selection = _allEmployeesData.where((e) => _selectedChapas.contains(e.employee.id)).toList();

    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))),
    );

    try {
       final pdf = pw.Document();
       final president = await _getCommissionPresident();
       
       for (var item in selection) {
          // Determine Cycle Stage
          // Assuming _currentTrienniumStart is global or fetched. 
          // If not available, we need to fetch it or use the employee's admission date logic if complex.
          // However, the rule "2024 is Year 3 of 2022-2024" implies a fixed triennium system.
          // Let's rely on _referenceYear relative to _currentTrienniumStart (or a calculated start).
          
          // Fallback: If _currentTrienniumStart is not set in this scope, use a default or derive from Year.
          // Actually, `_loadCycleData` likely fetches cycle info.
          // Let's use simple logic: 
          // Year 1: _referenceYear % 3 == 0 (if valid) ??
          // Better: The User said "Ano 1: Início", "Ano 2: Meio", "Ano 3: Fim".
          // And "Reference Year" is selected.
          
          // Let's assume the Start Year is needed.
          // For now, I will use a placeholder logic that calculates the offset from a base year (e.g. 2022).
          // OR, look for `currentTrienniumStart` in the file.
          int stage = 3; // Default to Final
          
          // Logic: Calculate based on employee admission or system cycle. 
          // User Requirement: "baseado no currentTrienniumStart e no Ano de Referência selecionado"
          // Logic: Calculate based on employee admission or system cycle. 
          // User Requirement: "baseado no currentTrienniumStart e no Ano de Referência selecionado"
          // UPDATE: User feedback indicates date-based logic failed for some cases ("1 nota showing Anexo XI").
          // Safe fallback: Use the COUNT of evaluations found in the cycle window.
          // This ensures that an employee with only 1 evaluation gets the Year 1 document, etc.
          
          // Etapa = posição do ano de referência dentro do triênio do funcionário
          // (currentTrienniumStart). Não depende de quantas avaliações existem,
          // senão quem teve afastamento (ano sem nota) cai no anexo errado.
          final startYear = item.cycleYears.first;
          int cycleYear = _referenceYear - startYear + 1;
          // Clamp to 1-3 range
          if (cycleYear < 1) cycleYear = 1;
          if (cycleYear > 3) cycleYear = 3;

          if (cycleYear == 1) {
              await _pdfService.buildAnexoX(pdf, item.employee, item.evaluations, _referenceYear, president: president, startYearOverride: startYear, scoresOverride: item.scores);
          } else if (cycleYear == 2) {
              await _pdfService.buildAnexoXI(pdf, item.employee, item.evaluations, _referenceYear, president: president, startYearOverride: startYear, scoresOverride: item.scores);
          } else {
              // Year 3 (Final)
              await _pdfService.buildAnexoXII(
                pdf, 
                item.employee, 
                item.evaluations, 
                _referenceYear,
                president: president,
                recomendacaoResult: _resultTextController.text,
                recomendacaoIndex: _selectedRecommendationIndex,
                startYearOverride: startYear,
                scoresOverride: item.scores,
              );
          }
       }
       
       Navigator.pop(context);

       final bytes = await pdf.save();
       final fileName = 'Encerramento_Ciclo_${DateTime.now().millisecondsSinceEpoch}.pdf';
       
       await Printing.layoutPdf(onLayout: (_) => Future.value(bytes), name: fileName);

    } catch (e) {
       Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }



  pw.Widget _buildRadioOption(String text, int index) {

     final selected = _selectedRecommendationIndex == index;

     return pw.Padding(

        padding: const pw.EdgeInsets.symmetric(vertical: 2),

        child: pw.Row(children: [

           pw.Container(

              width: 12, height: 12,

              decoration: pw.BoxDecoration(border: pw.Border.all(), color: selected ? PdfColors.black : null),

           ),

           pw.SizedBox(width: 8),

           pw.Text(text)

        ])

     );

  }



  @override

  Widget build(BuildContext context) {

    return Column(

       children: [

          // FILTERS

          Container(

             color: Colors.grey.shade100,

             padding: const EdgeInsets.all(16),

             child: Column(

                children: [

                   // Ref Year & Search

                   Row(children: [

                      Expanded(

                        child: DropdownButtonFormField<int>(

                           value: _referenceYear,

                           decoration: const InputDecoration(labelText: 'Ano de Referência', border: OutlineInputBorder()),

                           items: List.generate(5, (i) {

                              final y = DateTime.now().year - i;

                              return DropdownMenuItem(value: y, child: Text(y.toString()));

                           }),

                           onChanged: (v) {

                              if (v != null) {

                                 setState(() => _referenceYear = v);

                                 _loadCycleData();

                              }

                           }

                        )

                      ),

                      const SizedBox(width: 16),

                      // Search

                      Expanded(

                         flex: 2,

                         child: TextField(

                            decoration: const InputDecoration(labelText: 'Buscar Chapa/Nome', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),

                            onChanged: (v) { _searchQuery = v.toLowerCase(); _applyFilters(); }

                         )

                      )

                   ]),

                   const SizedBox(height: 12),

                   // Advanced Filters
                   SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          IntrinsicWidth(
                            child: ExpandableFilterSection(
                               title: 'Média do Triênio',
                               count: _filtrosMedia.length,
                               child: Wrap(spacing: 8, children: [
                                  FilterChip(label: const Text('Ótimo (>70)'), selected: _filtrosMedia.contains('High'), onSelected: (s) { setState(() { s ? _filtrosMedia.add('High') : _filtrosMedia.remove('High'); _applyFilters(); }); }),
                                  FilterChip(label: const Text('Médio (50-70)'), selected: _filtrosMedia.contains('Med'), onSelected: (s) { setState(() { s ? _filtrosMedia.add('Med') : _filtrosMedia.remove('Med'); _applyFilters(); }); }),
                                  FilterChip(label: const Text('Baixo (20-50)'), selected: _filtrosMedia.contains('Low'), onSelected: (s) { setState(() { s ? _filtrosMedia.add('Low') : _filtrosMedia.remove('Low'); _applyFilters(); }); }),
                                  FilterChip(label: const Text('Crítico (<20)'), selected: _filtrosMedia.contains('Critical'), onSelected: (s) { setState(() { s ? _filtrosMedia.add('Critical') : _filtrosMedia.remove('Critical'); _applyFilters(); }); }),
                               ])
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Situacao
                          IntrinsicWidth(
                            child: ExpandableFilterSection(
                              title: 'Situação',
                              count: _filtrosSituacao.length,
                              child: MultiSituacaoFilter(selectedSituacoes: _filtrosSituacao, availableSituacoes: _availableSituacoes.toSet(), onChanged: (v) { setState(() => _filtrosSituacao = v); _applyFilters(); })
                            ),
                          ),

                           const SizedBox(width: 8),

                           // Tipo
                           IntrinsicWidth(
                             child: ExpandableFilterSection(
                               title: 'Tipo',
                               count: _filtrosTipo.length,
                               child: MultiTipoFilter(selectedTipos: _filtrosTipo, availableTipos: _availableTipos.toSet(), onChanged: (v) { setState(() => _filtrosTipo = v); _applyFilters(); })
                             ),
                          ),
                          const SizedBox(width: 8),

                          // Status
                          IntrinsicWidth(
                             child: ExpandableFilterSection(
                               title: 'Status',
                               count: _filtrosStatus.length,
                               child: Wrap(spacing: 8, children: [
                                  FilterChip(
                                    label: const Text('Pendência (Comissão)'), 
                                    selected: _filtrosStatus.contains('PENDENTE'), 
                                    avatar: const Icon(Icons.flag, size: 16, color: Colors.red),
                                    onSelected: (s) { setState(() { s ? _filtrosStatus.add('PENDENTE') : _filtrosStatus.remove('PENDENTE'); _applyFilters(); }); }
                                  ),
                                  FilterChip(
                                    label: const Text('Concluída'), 
                                    selected: _filtrosStatus.contains('CONCLUIDA'), 
                                    avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    onSelected: (s) { setState(() { s ? _filtrosStatus.add('CONCLUIDA') : _filtrosStatus.remove('CONCLUIDA'); _applyFilters(); }); }
                                  ),
                               ])
                             ),
                          )
                       ]),
                   )
                ]
             )
          ),



          // RESULTS TABLE

          Expanded(

             child: _isLoading ? const Center(child: CircularProgressIndicator()) : 

             Column(

               children: [

                  // Batch Config Header

                  Container(

                     color: Colors.blue.shade50,

                     padding: const EdgeInsets.all(16),

                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        const Text('Configuração de Saída em Lote (Anexo XII)', style: TextStyle(fontWeight: FontWeight.bold)),

                        const SizedBox(height: 8),

                        Row(children: [

                           Expanded(

                              child: TextField(

                                 controller: _resultTextController,

                                 decoration: const InputDecoration(labelText: 'Resultado (Texto)', hintText: 'Ex: Apto para progressão', border: OutlineInputBorder(), isDense: true)

                              )

                           ),

                           const SizedBox(width: 16),

                           Expanded(

                              child: DropdownButtonFormField<int>(

                                 value: _selectedRecommendationIndex,

                                 decoration: const InputDecoration(labelText: 'Recomendação', border: OutlineInputBorder(), isDense: true),

                                 items: const [

                                    DropdownMenuItem(value: 0, child: Text('Arquivamento')),

                                    DropdownMenuItem(value: 1, child: Text('Recuperação')),

                                    DropdownMenuItem(value: 2, child: Text('Demissão')),

                                    DropdownMenuItem(value: 3, child: Text('Progressão Horiz.')),

                                    DropdownMenuItem(value: 4, child: Text('Progressão Vert.')),

                                 ],

                                 onChanged: (v) => setState(() => _selectedRecommendationIndex = v)

                              )

                           ),

                           const SizedBox(width: 16),

                           OutlinedButton.icon(
                              icon: const Icon(Icons.table_view),
                              label: const Text('Excel RH'),
                              onPressed: _isLoading ? null : _exportarExcelRH,
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                           ),

                           const SizedBox(width: 16),

                           ElevatedButton.icon(

                              icon: const Icon(Icons.print),

                              label: Text('Gerar Docs (${_selectedChapas.length})'),

                              onPressed: _generateBatchPDF,

                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16))

                           )

                        ])

                     ])

                  ),

                  

                  // Table Header

                  Container(

                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                     color: Colors.grey.shade200,

                     child: Row(children: [

                        Checkbox(

                           value: _filteredEmployeesData.isNotEmpty && _selectedChapas.length == _filteredEmployeesData.length,

                           onChanged: (v) => _toggleAllFiltered()

                        ),

                        const Expanded(flex: 3, child: Text('Funcionário', style: TextStyle(fontWeight: FontWeight.bold))),

                        const Expanded(flex: 2, child: Text('Ciclo', style: TextStyle(fontWeight: FontWeight.bold))),

                        const Expanded(flex: 3, child: Text('Notas (Ano 1 / 2 / 3)', style: TextStyle(fontWeight: FontWeight.bold))),

                        const Expanded(flex: 1, child: Text('Média', style: TextStyle(fontWeight: FontWeight.bold))),

                     ])

                  ),

                  

                  // List

                  Expanded(

                     child: ListView.separated(

                        itemCount: _filteredEmployeesData.length,

                        separatorBuilder: (_,__) => const Divider(height: 1),

                        itemBuilder: (context, index) {

                           final data = _filteredEmployeesData[index];

                           final isSelected = _selectedChapas.contains(data.employee.id);

                           return Container(

                              color: isSelected ? Colors.blue.shade50 : null,

                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                              child: Row(

                                 children: [

                                    Checkbox(

                                       value: isSelected,

                                       onChanged: (v) => setState(() => v! ? _selectedChapas.add(data.employee.id) : _selectedChapas.remove(data.employee.id))

                                    ),

                                    Expanded(

                                       flex: 3,

                                       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Row(
                                            children: [
                                              Expanded(child: Text(data.employee.nome, style: const TextStyle(fontWeight: FontWeight.bold))),
                                              if (data.hasPendingDisciplinary)
                                                 IconButton(
                                                   icon: const Icon(Icons.flag, color: Colors.red),
                                                   tooltip: 'Ocorrência Disciplinar Pendente (Clique para resolver)',
                                                   onPressed: () => _confirmarProvaFisica(data.employee, data.evaluations),
                                                 )
                                            ],
                                          ),
                                          Text('${data.employee.id} • ${data.employee.funcao}', style: const TextStyle(fontSize: 12, color: Colors.grey))
                                       ])

                                    ),

                                    Expanded(flex: 2, child: Text('${data.cycleYears.first}-${data.cycleYears.last}')),

                                    Expanded(

                                       flex: 3,

                                       child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: data.cycleYears.map((y) {

                                          final s = data.scores[y];

                                          return Text(s?.toStringAsFixed(1) ?? '-', style: TextStyle(color: s == null ? Colors.red : Colors.black));

                                       }).toList())

                                    ),

                                    Expanded(

                                       flex: 1, 

                                       child: Text(data.average.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: _getAvgColor(data.average)))

                                    ),

                                 ]

                              )

                           );

                        }

                     )

                  )

               ]

             )

          )

       ]

    );

  }



  Color _getAvgColor(double avg) {

     if (avg >= 70) return Colors.green;

     if (avg >= 50) return Colors.orange;

     return Colors.red;

  }

  Future<void> _confirmarProvaFisica(Employee emp, List<Evaluation> evals) async {
     // Intro Dialog
     final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
           title: const Text('Confirmar Prova Física'),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                const Icon(Icons.warning, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                Text('O funcionário ${emp.nome} possui Ocorrência Disciplinar sinalizada.'),
                const SizedBox(height: 8),
                const Text('Confirma que a PROVA FÍSICA foi entregue à comissão?'),
                const SizedBox(height: 8),
                const Text('Isso liberará a nota e concluirá a avaliação.', style: TextStyle(fontSize: 12, color: Colors.grey)),
             ],
           ),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                 onPressed: () => Navigator.pop(ctx, true),
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                 child: const Text('Confirmar Entrega'),
              )
           ],
        )
     );

     if (confirm != true) return;

     setState(() => _isLoading = true);

     try {
        final batch = _firestore.batch();
        int count = 0;

        for (var ev in evals) {
           if (ev.status == 'aguardando_comissao' || (ev.pdfData != null && ev.pdfData!['ocorrenciaDisciplinar'] == true && ev.status != 'concluida')) {
              final ref = _firestore.collection('evaluations').doc(ev.id);
              batch.update(ref, {
                 'status': 'concluida', 
                 'waitingCommissionProof': false, // Check flag
                 'updatedAt': FieldValue.serverTimestamp()
              });
              count++;
           }
        }

        if (count > 0) {
           await batch.commit();
           await _loadCycleData(); // Reload to update UI
           
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status atualizado! $count avaliações concluídas.')));
           }
        } else {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma avaliação pendente encontrada para atualizar.')));
           }
        }

     } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
        }
     } finally {
        setState(() => _isLoading = false);
     }
  }

}



class EmployeeCycleData {
  final Employee employee;
  final double average;
  final Map<int, double?> scores;
  final List<int> cycleYears;
  final List<Evaluation> evaluations;
  final bool hasPendingDisciplinary; // New field

  EmployeeCycleData({
    required this.employee, 
    required this.average, 
    required this.scores, 
    required this.cycleYears, 
    required this.evaluations,
    this.hasPendingDisciplinary = false,
  });
}

