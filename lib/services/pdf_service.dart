import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';

class PdfService {
  Future<Uint8List> generateAnexoI(Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final pdf = pw.Document();
    await buildAnexoI(pdf, employee, evaluation, questions, cycle);
    return pdf.save();
  }

  Future<void> buildAnexoI(pw.Document pdf, Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final startYear = cycle - 1;
    final endYear = cycle;
    final periodoAvaliacao = '01/10/$startYear a 30/09/$endYear';

    pw.ImageProvider? signatureImage;
    if (evaluation?.signatureUrl != null && evaluation!.signatureUrl!.isNotEmpty) {
      try {
        signatureImage = await networkImage(evaluation.signatureUrl!);
      } catch (e) {
        // Fallback or ignore
        print('Error loading signature image: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(periodoAvaliacao, evaluation),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlock(evaluation),
              pw.Expanded(
                child: _buildEvaluationMatrix(evaluation, questions, 'OPERACIONAL'),
              ),
              _buildFooter(evaluation, questions, 'OPERACIONAL'),
              _buildSignatures(evaluation, signatureImage, label: 'Empregado'),
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildHeader(String periodoAvaliacao, Evaluation? evaluation) {
    // Defaults
    bool isAde = false;
    bool isAdo = true;

    if (evaluation?.pdfData != null) {
        final type = evaluation!.pdfData!['tipoAvaliacao'] as String? ?? 'ADO';
        isAde = type == 'ADE';
        isAdo = type == 'ADO';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          // Título (ANEXO I) com linha horizontal abaixo
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide()),
            ),
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'ANEXO I - a ser preenchido pelo próprio empregado que não assume funções gerenciais',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
          // Conteúdo principal: Empresa (esquerda) + Período boxed (direita)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Coluna Esquerda: Empresa, Processo, CTEA
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Empresa de Desenvolvimento de Itabira Ltda.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Processo de Avaliação de Desempenho Individual',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'C.T.E.A. (Condições de Trabalho do Empregado Avaliado)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              // Coluna Direita: Período de Avaliação (BOX DENTRO)
              pw.Container(
                width: 180,
                margin: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  children: [
                    pw.Text('Período de Avaliação', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(periodoAvaliacao, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('Tipo', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('ADE', checked: isAde),
                        pw.SizedBox(width: 15),
                        _buildCheckbox('ADO', checked: isAdo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIdentificationBlock(Employee employee) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Column(
        children: [
          // Linhas 1-2: Empregado/Matrícula e Emprego/Data (coluna direita estreita ~180px)
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FixedColumnWidth(180),
            },
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(),
              verticalInside: pw.BorderSide(),
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                children: [
                  _buildCellContent('Empregado:', employee.nome),
                  _buildCellContent('Matrícula:', employee.id),
                ]
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                children: [
                  _buildCellContent('Emprego Público:', employee.funcao),
                  _buildCellContent('Data de Admissão:', employee.admissao),
                ]
              ),
            ],
          ),
          // Linhas 3-4: Nível/Grau/Vencimento | Escolaridades (coluna direita larga ~250px)
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder(
              verticalInside: pw.BorderSide(),
            ),
            children: [
              // Linha 3: Nível/Grau | Escolaridade Ingresso
              pw.TableRow(
                children: [
                  // Esquerda: Nível | Grau (COM borda inferior)
                  pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                    child: pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(5),
                        1: const pw.FlexColumnWidth(2),
                      },
                      border: pw.TableBorder(verticalInside: pw.BorderSide()),
                      children: [
                        pw.TableRow(
                          children: [
                            _buildCellContent('Nível:', employee.nivel),
                            _buildCellContent('Grau:', employee.faixa),
                          ]
                        )
                      ]
                    ),
                  ),
                  // Direita: Escolaridade Ingresso (SEM borda inferior)
                  _buildCellContent('Escolaridade de Ingresso:', employee.escolaridadeIngresso ?? ''),
                ]
              ),
              // Linha 4: Vencimento | Escolaridade Atual
              pw.TableRow(
                decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                children: [
                  _buildCellContent('Vencimento:', employee.vencimento != null ? 'R\$ ${employee.vencimento}' : ''),
                  _buildCellContent('Escolaridade Atual:', employee.escolaridadeAtual ?? ''),
                ]
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCellContent(String label, String value) {
     return pw.Padding(
       padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
       child: _buildCellText(label, value),
     );
  }

  pw.Widget _buildCellText(String label, String value) {
    return pw.Row(
       children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9)),
          pw.SizedBox(width: 5),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
       ]
    );
  }

  pw.Widget _buildTableCell(String label, String value) {
     return _buildCellContent(label, value); // Reusing for compatibility
  }

  pw.Widget _buildFunctionalSituationBlock(Evaluation? evaluation) {
    // Defaults
    bool ocorrenciaSim = false;
    bool ocorrenciaNao = true;
    
    bool comissionado = false;
    bool disponibilidade = false;
    bool desvio = false;
    bool provimento = false;

    bool condicaoSim = true;
    bool condicaoNao = false;

    if (evaluation?.pdfData != null) {
        final data = evaluation!.pdfData!;
        final ocorrencia = data['ocorrenciaDisciplinar'] as bool? ?? false;
        ocorrenciaSim = ocorrencia;
        ocorrenciaNao = !ocorrencia;

        comissionado = data['empregoComissionado'] as bool? ?? false;
        disponibilidade = data['disponibilidade'] as bool? ?? false;
        desvio = data['desvioFuncao'] as bool? ?? false;
        provimento = data['empregoProvimento'] as bool? ?? false;

        final condicao = data['condicoesAvaliacao'] as bool? ?? true;
        condicaoSim = condicao;
        condicaoNao = !condicao;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(), right: pw.BorderSide(), bottom: pw.BorderSide()),
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(110),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FixedColumnWidth(140),
        },
        border: pw.TableBorder(verticalInside: pw.BorderSide()),
        children: [
          pw.TableRow(
            children: [
              // Coluna 1: Ocorrência disciplinar
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Ocorrência disciplinar:', style: pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('SIM', checked: ocorrenciaSim),
                        pw.SizedBox(width: 10),
                        _buildCheckbox('NÃO', checked: ocorrenciaNao),
                      ],
                    ),
                  ],
                ),
              ),
              // Coluna 2: Lista de checkboxes
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildCheckboxRow('Emprego Público comissionado:', checked: comissionado),
                    _buildCheckboxRow('Disponibilidade:', checked: disponibilidade),
                    _buildCheckboxRow('Desvio de função:', checked: desvio),
                    _buildCheckboxRow('Emprego Público de provimento:', checked: provimento),
                  ],
                ),
              ),
              // Coluna 3: Tem condições de avaliação
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('Tem condições de avaliação?', style: pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('SIM', checked: condicaoSim),
                        pw.SizedBox(width: 10),
                        _buildCheckbox('NÃO', checked: condicaoNao),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCheckboxRow(String text, {required bool checked}) {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 8))),
        _buildCheckbox('', checked: checked),
      ],
    );
  }

  pw.Widget _buildCheckbox(String label, {bool checked = false}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: checked ? pw.Center(child: pw.Text('X', style: pw.TextStyle(fontSize: 8))) : null,
        ),
        pw.SizedBox(width: 3),
        pw.Text(label, style: pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  int? _getScore(Evaluation? evaluation, String questionId) {
    if (evaluation == null) return null;
    return evaluation.answers[questionId];
  }

  pw.Widget _buildEvaluationMatrix(Evaluation? evaluation, List<Map<String, dynamic>> questions, String requiredType) {
    // Filter only active questions AND type
    final activeQuestions = questions.where((q) {
      final isActive = q['ativo'] as bool? ?? false; 
      final type = q['tipo'] as String? ?? ''; 
      return isActive && type == requiredType;
    }).toList();
    
    // Sort by ordem
    activeQuestions.sort((a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0));
    
    // Group by secao and subsecao
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};
    
    for (var q in activeQuestions) {
      final secao = q['secao'] as String? ?? '';
      final subsecao = q['subsecao'] as String? ?? '';
      
      if (!grouped.containsKey(secao)) {
        grouped[secao] = {};
      }
      if (!grouped[secao]!.containsKey(subsecao)) {
        grouped[secao]![subsecao] = [];
      }
      grouped[secao]![subsecao]!.add(q);
    }

    final List<pw.TableRow> rows = [];
    int questionIndex = 0;
    
    // Sort secoes
    final sortedSecoes = grouped.keys.toList()..sort();
    
    for (var secao in sortedSecoes) {
      // Add secao header
      rows.add(_buildSectionHeaderRow(secao));
      
      final subsecoes = grouped[secao]!;
      final sortedSubsecoes = subsecoes.keys.toList()..sort();
      
      for (var subsecao in sortedSubsecoes) {
        // Add subsecao header
        rows.add(_buildSubsectionHeaderRow(subsecao));
        
        // Extract prefix from subsecao or secao
        String prefix = '';
        if (subsecao.isNotEmpty && subsecao.contains(' -')) {
            prefix = subsecao.split(' -')[0].trim();
        } else if (subsecao.isEmpty && secao.contains(' -')) {
            // Fallback: use Section numbering (e.g., "II") if subsection is empty
            prefix = secao.split(' -')[0].trim();
        }

        final perguntas = subsecoes[subsecao]!;
        
        for (int i = 0; i < perguntas.length; i++) {
          final pergunta = perguntas[i];
          final rawText = pergunta['pergunta'] as String;
          final legacyQuestionId = 'q$questionIndex'; 
          final stableQuestionId = pergunta['id'] as String? ?? ''; 
          
          questionIndex++;
          
          // Construct numbered text: "I.1.1 - texto"
          String numberedText = rawText;
          if (prefix.isNotEmpty) {
              numberedText = '$prefix.${i + 1} - $rawText';
          }

          // Try stable ID first, then legacy fallback
          final score = _getScore(evaluation, stableQuestionId) ?? _getScore(evaluation, legacyQuestionId);
          
          rows.add(_buildQuestionTableRow(numberedText, score, true)); // Always border for now, cleaner
        }
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(),
          right: pw.BorderSide(),
          bottom: pw.BorderSide(),
        ),
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1), // Takes remaining space
          1: const pw.FixedColumnWidth(140), // Matches Functional Block Column 3 + Separator
          // Functional Block Cols: 110 (Fixed) | Flex(2) | 140 (Fixed)
          // Wait. The Functional block has 3 cols. The separator is between col 2 and 3.
          // The vertical line is at X = Width - 140.
          // So here, if we have 2 cols, and we want the vertical line at X = Width - 140,
          // Col 2 must be Fixed(140). Col 1 is Flex.
          // Correct.
        },
        border: pw.TableBorder(verticalInside: pw.BorderSide()),
        children: rows,
      ),
    );
  }

  pw.TableRow _buildSectionHeaderRow(String text) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(), // Coluna vazia
      ],
    );
  }

  pw.TableRow _buildSubsectionHeaderRow(String text) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(), // Coluna vazia
      ],
    );
  }

  pw.TableRow _buildQuestionTableRow(String text, int? score, bool withBorder) {
    return pw.TableRow(
      decoration: withBorder ? pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 9)),
        ),
        pw.Center(
          child: score != null 
            ? pw.Text('$score', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))
            : pw.Text('', style: pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }



  pw.Widget _buildFooter(Evaluation? evaluation, List<Map<String, dynamic>> questions, String requiredType) {
    // Calculate Total Score
    int totalScore = 0;
    if (evaluation != null) {
      final activeQuestions = questions.where((q) {
        final isActive = q['ativo'] as bool? ?? false;
        final type = q['tipo'] as String? ?? '';
        return isActive && type == requiredType;
      }).toList();

      activeQuestions.sort((a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0));
      
      int index = 0;
      for (var q in activeQuestions) {
        final stableId = q['id'] as String? ?? '';
        final legacyId = 'q$index';
        
        final val = evaluation.answers[stableId] ?? evaluation.answers[legacyId];
        if (val is int) {
          totalScore += val;
        }
        index++;
      }
    }

    final obsText = (evaluation?.obs != null && evaluation!.obs!.trim().isNotEmpty)
        ? evaluation.obs!
        : 'NADA CONSTA';

    return pw.Container(
       decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(), right: pw.BorderSide(), bottom: pw.BorderSide())
       ),
       child: pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(1), 
            1: const pw.FixedColumnWidth(140),
          },
          border: pw.TableBorder(verticalInside: pw.BorderSide()),
          children: [
             pw.TableRow(
                children: [
                   // Obs Column
                   pw.Container(
                     height: 40,
                     padding: const pw.EdgeInsets.all(5),
                     child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                           pw.Text('Obs.:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                           pw.Text(obsText, style: pw.TextStyle(fontSize: 9)),
                        ]
                     ),
                   ),
                   // Total Column (Centered)
                   pw.Container(
                      height: 40,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5),
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Row(
                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                         children: [
                            pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            if (evaluation != null)
                              pw.Text('$totalScore', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                         ]
                      )
                   )
                ]
             )
          ]
       )
    );
  }

  pw.Widget _buildSignatures(Evaluation? evaluation, pw.ImageProvider? signatureImage, {String label = 'Empregado'}) {
      String dateStr = '____ de _______________ de 20__';
      
      if (evaluation != null) {
        final date = evaluation.createdAt;
        final day = date.day.toString().padLeft(2, '0');
        final monthName = _getMonthName(date.month);
        final year = date.year;
        dateStr = '$day de $monthName de $year';
      }

      return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 40),
          child: pw.Column(
              children: [
                   pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                          pw.Text('Itabira, em $dateStr', style: pw.TextStyle(fontSize: 10)),
                      ]
                   ),
                   pw.SizedBox(height: 30), // Reduced height to accommodate image
                   if (signatureImage != null)
                      pw.Container(
                        height: 50,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      )
                   else
                      pw.SizedBox(height: 50),
                   
                   pw.Container(
                       width: 250,
                       decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                   ),
                   pw.SizedBox(height: 2),
                   pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]
          ),
      );
  }

  /// Anexo II - Avaliação do Gestor (Operacional)
  Future<Uint8List> generateAnexoII(Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final pdf = pw.Document();
    await buildAnexoII(pdf, employee, evaluation, questions, cycle);
    return pdf.save();
  }

  Future<void> buildAnexoII(pw.Document pdf, Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final startYear = cycle - 1;
    final endYear = cycle;
    final periodoAvaliacao = '01/10/$startYear a 30/09/$endYear';

    pw.ImageProvider? signatureImage;
    if (evaluation?.signatureUrl != null && evaluation!.signatureUrl!.isNotEmpty) {
      try {
        signatureImage = await networkImage(evaluation.signatureUrl!);
      } catch (e) {
        print('Error loading signature image: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderAnexoII(periodoAvaliacao, evaluation),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlock(evaluation),
              pw.Expanded(
                child: _buildEvaluationMatrix(evaluation, questions, 'OPERACIONAL'),
              ),
              _buildFooter(evaluation, questions, 'OPERACIONAL'),
              _buildSignatures(evaluation, signatureImage, label: 'Chefia Imediata'),
            ],
          );
        },
      ),
    );
  }

  /// Anexo III - Consolidado Operacional (Média AUTO + GESTOR)
  Future<Uint8List> generateAnexoIII(
    Employee employee,
    Evaluation? autoEval,
    Evaluation? gestorEval,
    List<Map<String, dynamic>> questions,
    int cycle,
  ) async {
    final pdf = pw.Document();
    await buildAnexoIII(pdf, employee, autoEval, gestorEval, questions, cycle);
    return pdf.save();
  }

  Future<void> buildAnexoIII(
    pw.Document pdf,
    Employee employee,
    Evaluation? autoEval,
    Evaluation? gestorEval,
    List<Map<String, dynamic>> questions,
    int cycle,
  ) async {
    final startYear = cycle - 1;
    final endYear = cycle;
    final periodoAvaliacao = '01/10/$startYear a 30/09/$endYear';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderAnexoIII(periodoAvaliacao, autoEval),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlockConsolidated(autoEval, gestorEval),
              pw.Expanded(
                child: _buildConsolidatedMatrix(autoEval, gestorEval, questions, 'OPERACIONAL'),
              ),
              _buildConsolidatedFooter(autoEval, gestorEval, questions, 'OPERACIONAL'),
              _buildConsolidatedSignatures(), 
            ],
          );
        },
      ),
    );
  }

  /// Anexo IV - Autoavaliação Gerencial
  Future<Uint8List> generateAnexoIV(Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final pdf = pw.Document();
    await buildAnexoIV(pdf, employee, evaluation, questions, cycle);
    return pdf.save();
  }

  Future<void> buildAnexoIV(pw.Document pdf, Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final startYear = cycle - 1;
    final endYear = cycle;
    final periodoAvaliacao = '01/10/$startYear a 30/09/$endYear';

    pw.ImageProvider? signatureImage;
    if (evaluation?.signatureUrl != null && evaluation!.signatureUrl!.isNotEmpty) {
      try {
        signatureImage = await networkImage(evaluation.signatureUrl!);
      } catch (e) {
        print('Error loading signature image: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderAnexoIV(periodoAvaliacao, evaluation),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlock(evaluation),
              pw.Expanded(
                child: _buildEvaluationMatrix(evaluation, questions, 'GERENCIAL'),
              ),
              _buildFooter(evaluation, questions, 'GERENCIAL'),
              _buildSignatures(evaluation, signatureImage, label: 'Empregado'),
            ],
          );
        },
      ),
    );
  }

  /// Anexo V - Avaliação do Gestor (Gerencial)
  Future<Uint8List> generateAnexoV(Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final pdf = pw.Document();
    await buildAnexoV(pdf, employee, evaluation, questions, cycle);
    return pdf.save();
  }

  Future<void> buildAnexoV(pw.Document pdf, Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final startYear = cycle - 1;
    final endYear = cycle;
    final periodoAvaliacao = '01/10/$startYear a 30/09/$endYear';

    pw.ImageProvider? signatureImage;
    if (evaluation?.signatureUrl != null && evaluation!.signatureUrl!.isNotEmpty) {
      try {
        signatureImage = await networkImage(evaluation.signatureUrl!);
      } catch (e) {
        print('Error loading signature image: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderAnexoV(periodoAvaliacao, evaluation),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlock(evaluation),
              pw.Expanded(
                child: _buildEvaluationMatrix(evaluation, questions, 'GERENCIAL'),
              ),
              _buildFooter(evaluation, questions, 'GERENCIAL'),
              _buildSignatures(evaluation, signatureImage, label: 'Chefia Imediata'),
            ],
          );
        },
      ),
    );
  }

  /// Anexo VI - Consolidado Gerencial (Média AUTO_GERENCIAL + GESTOR_GERENCIAL)
  Future<Uint8List> generateAnexoVI(
    Employee employee,
    Evaluation? autoEval,
    Evaluation? gestorEval,
    List<Map<String, dynamic>> questions,
    int cycle,
  ) async {
    final pdf = pw.Document();
    await buildAnexoVI(pdf, employee, autoEval, gestorEval, questions, cycle);
    return pdf.save();
  }

  Future<void> buildAnexoVI(
    pw.Document pdf,
    Employee employee,
    Evaluation? autoEval,
    Evaluation? gestorEval,
    List<Map<String, dynamic>> questions,
    int cycle,
  ) async {
    final startYear = cycle - 1;
    final endYear = cycle;
    final periodoAvaliacao = '01/10/$startYear a 30/09/$endYear';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeaderAnexoVI(periodoAvaliacao, autoEval),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlockConsolidated(autoEval, gestorEval),
              pw.Expanded(
                child: _buildConsolidatedMatrix(autoEval, gestorEval, questions, 'GERENCIAL'),
              ),
              _buildConsolidatedFooter(autoEval, gestorEval, questions, 'GERENCIAL'),
              _buildConsolidatedSignatures(), 
            ],
          );
        },
      ),
    );
  }

  // ========== BUILD METHODS FOR NEW ANEXOS ==========

  pw.Widget _buildHeaderAnexoII(String periodoAvaliacao, Evaluation? evaluation) {
    bool isAde = false;
    bool isAdo = true;

    if (evaluation?.pdfData != null) {
      final type = evaluation!.pdfData!['tipoAvaliacao'] as String? ?? 'ADO';
      isAde = type == 'ADE';
      isAdo = type == 'ADO';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide()),
            ),
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'ANEXO II - a ser preenchido pelas chefias imediatas do empregado e complementado com provas materiais dos apontamentos de ordem subjetiva, devendo estas provas serem anexadas ao formulário.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Empresa de Desenvolvimento de Itabira Ltda.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Processo de Avaliação de Desempenho Individual',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'I.C.E.A. / F.C.A.O. Informação da Chefia do Empregado Avaliado / Fatores Comportamentais, Atitudinais e Operacionais.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 180,
                margin: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  children: [
                    pw.Text('Período de Avaliação', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(periodoAvaliacao, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('Tipo', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('ADE', checked: isAde),
                        pw.SizedBox(width: 15),
                        _buildCheckbox('ADO', checked: isAdo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderAnexoIII(String periodoAvaliacao, Evaluation? evaluation) {
    bool isAde = false;
    bool isAdo = true;

    if (evaluation?.pdfData != null) {
      final type = evaluation!.pdfData!['tipoAvaliacao'] as String? ?? 'ADO';
      isAde = type == 'ADE';
      isAdo = type == 'ADO';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide()),
            ),
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'ANEXO III - a ser preenchido pela Comissão de Gestão de Carreiras a partir dos dados coletados dos Formulários dos itens I e II',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Empresa de Desenvolvimento de Itabira Ltda.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Processo de Avaliação de Desempenho Individual',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'A.F.E.A. / F.C.A.O. Avaliação Final do Empregado Avaliado/ Fatores Comportamentais, Atitudinais e Operacionais.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 180,
                margin: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  children: [
                    pw.Text('Período de Avaliação', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(periodoAvaliacao, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('Tipo', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('ADE', checked: isAde),
                        pw.SizedBox(width: 15),
                        _buildCheckbox('ADO', checked: isAdo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderAnexoIV(String periodoAvaliacao, Evaluation? evaluation) {
    bool isAde = false;
    bool isAdo = true;

    if (evaluation?.pdfData != null) {
      final type = evaluation!.pdfData!['tipoAvaliacao'] as String? ?? 'ADO';
      isAde = type == 'ADE';
      isAdo = type == 'ADO';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide()),
            ),
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'ANEXO IV - a ser preenchido pelo próprio empregado que assume funções gerenciais',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Empresa de Desenvolvimento de Itabira Ltda.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Processo de Avaliação de Desempenho Individual',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'C.T.E.A./F.G. Condições de Trabalho do Empregado Avaliado/Fatores Gerenciais.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 180,
                margin: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  children: [
                    pw.Text('Período de Avaliação', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(periodoAvaliacao, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('Tipo', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('ADE', checked: isAde),
                        pw.SizedBox(width: 15),
                        _buildCheckbox('ADO', checked: isAdo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderAnexoV(String periodoAvaliacao, Evaluation? evaluation) {
    bool isAde = false;
    bool isAdo = true;

    if (evaluation?.pdfData != null) {
      final type = evaluation!.pdfData!['tipoAvaliacao'] as String? ?? 'ADO';
      isAde = type == 'ADE';
      isAdo = type == 'ADO';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide()),
            ),
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'ANEXO V - a ser preenchido pelas chefias imediatas do empregado que assume funções gerenciais e complementado com provas materiais dos apontamentos de ordem subjetiva, devendo estas provas serem anexadas ao formulário.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Empresa de Desenvolvimento de Itabira Ltda.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Processo de Avaliação de Desempenho Individual',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'I.C.E.A./F.G. Informação da Chefia do Empregado Avaliado/Fatores Gerenciais.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 180,
                margin: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  children: [
                    pw.Text('Período de Avaliação', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(periodoAvaliacao, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('Tipo', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('ADE', checked: isAde),
                        pw.SizedBox(width: 15),
                        _buildCheckbox('ADO', checked: isAdo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderAnexoVI(String periodoAvaliacao, Evaluation? evaluation) {
    bool isAde = false;
    bool isAdo = true;

    if (evaluation?.pdfData != null) {
      final type = evaluation!.pdfData!['tipoAvaliacao'] as String? ?? 'ADO';
      isAde = type == 'ADE';
      isAdo = type == 'ADO';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide()),
            ),
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'ANEXO VI - a ser preenchido pela Comissão de Gestão de Carreiras a partir dos dados coletados dos Formulários dos itens IV e V',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Empresa de Desenvolvimento de Itabira Ltda.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Processo de Avaliação de Desempenho Individual',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'A.F.E.A./F.G. Avaliação Final do Empregado Avaliado/Fatores Gerenciais.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 180,
                margin: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  children: [
                    pw.Text('Período de Avaliação', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(periodoAvaliacao, style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('Tipo', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('ADE', checked: isAde),
                        pw.SizedBox(width: 15),
                        _buildCheckbox('ADO', checked: isAdo),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFunctionalSituationBlockConsolidated(Evaluation? autoEval, Evaluation? gestorEval) {
    // Use data from autoEval preferably, fallback to gestorEval
    final evaluation = autoEval ?? gestorEval;
    return _buildFunctionalSituationBlock(evaluation);
  }

  pw.Widget _buildConsolidatedMatrix(
    Evaluation? autoEval,
    Evaluation? gestorEval,
    List<Map<String, dynamic>> questions,
    String requiredType,
  ) {
    // Filter and sort
    final activeQuestions = questions.where((q) {
      final isActive = q['ativo'] as bool? ?? false; 
      final type = q['tipo'] as String? ?? ''; 
      return isActive && type == requiredType;
    }).toList();
    
    activeQuestions.sort((a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0));
    
    // Grouping
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var q in activeQuestions) {
      final secao = q['secao'] as String? ?? '';
      final subsecao = q['subsecao'] as String? ?? '';
      if (!grouped.containsKey(secao)) grouped[secao] = {};
      if (!grouped[secao]!.containsKey(subsecao)) grouped[secao]![subsecao] = [];
      grouped[secao]![subsecao]!.add(q);
    }

    final rows = <pw.TableRow>[];
    
    // Header Row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide())
        ),
        children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ),
            _buildCenteredHeader('PONTOS\nEMPREGADO'),
            _buildCenteredHeader('PONTOS\nCHEFIA\nDIRETA'),
            _buildCenteredHeader('MÉDIA\nFINAL'),
        ]
      )
    );

    int questionCounter = 1;
    final sortedSecoes = grouped.keys.toList()..sort();

    for (var secao in sortedSecoes) {
      // SECTION HEADER ROW
      // User Requirement: Sentence Case (No toUpperCase).
      // User Requirement: No line separating Section from Subsection.
      // Solution: REMOVE bottom border.
      rows.add(
        pw.TableRow(
          // No decoration here to avoid the bottom line? 
          // But we need the vertical borders if using Table?
          // If we rely on TableBorder.all for the container, we just need internal lines.
          // TableBorder(horizontalInside: none) means we define borders per row.
          // So if we omit bottom border here, it should merge!
          decoration: const pw.BoxDecoration(
             // No bottom border
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(secao, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)), // Sentence Case
            ),
            // We need to fill columns to maintain structure, borders handle vertical separation
            pw.Container(), pw.Container(), pw.Container()
          ]
        )
      );

      final subsecoes = grouped[secao]!;
      final sortedSubsecoes = subsecoes.keys.toList()..sort();

      for (var subsecao in sortedSubsecoes) {
          questionCounter = 1; 

          // SUBSECTION HEADER ROW
          // Usually needs a bottom border if it separates from questions.
          // But questions also have borders.
          // Let's add top border? No, Section has no bottom.
          // Just let it flow.
          if (subsecao.isNotEmpty) {
            rows.add(
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                   // No bottom border here either? Questions have it.
                   // Actually, usually headers are distinct. 
                   // If Section I sits on Subsection I.1, and there is no line, they look like one block.
                   // Then Question I.1.1 comes. It usually has a top line or the Subsection has a bottom line.
                   // User said "separando o caralho do titulo I do subtitulo I.1 q não tem".
                   // So NO line between Sec and Sub.
                   // And between Sub and Question? Usually yes.
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(subsecao, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Container(), pw.Container(), pw.Container()
                ]
              )
            );
          }

          final perguntas = subsecoes[subsecao]!;
          for (int i = 0; i < perguntas.length; i++) {
             final pergunta = perguntas[i];
             final rawText = pergunta['pergunta'] as String;
             final id = pergunta['id'] as String;

             String prefix = '';
             if (subsecao.contains(' -')) prefix = subsecao.split(' -')[0].trim();
             else if (secao.contains(' -')) prefix = secao.split(' -')[0].trim();

             String numberedText = rawText;
             if (prefix.isNotEmpty) {
                numberedText = '$prefix.$questionCounter - $rawText';
             } else {
                numberedText = '$questionCounter - $rawText';
             }
             questionCounter++;

             final autoScore = autoEval?.answers[id];
             final gestorScore = gestorEval?.answers[id];
             double? media;
             if (autoScore != null || gestorScore != null) {
                final a = (autoScore is int) ? autoScore : (autoScore as double? ?? 0);
                final g = (gestorScore is int) ? gestorScore : (gestorScore as double? ?? 0);
                media = (a + g) / 2.0;
             }

             // Questions: User wants NO separation from header.
             // Previous logic added 'top' border. Removing it.
             // Separation between questions is handled by the 'bottom' border of the previous question.
             rows.add(
               pw.TableRow(
                 decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide() // Only bottom border
                    )
                 ),
                 verticalAlignment: pw.TableCellVerticalAlignment.middle,
                 children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      child: pw.Text(numberedText, style: const pw.TextStyle(fontSize: 8)),
                    ),
                    _buildCenteredCell(autoScore?.toString() ?? ''),
                    _buildCenteredCell(gestorScore?.toString() ?? ''),
                    _buildCenteredCell(media?.toStringAsFixed(1) ?? ''),
                 ]
               )
             );
          }
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FixedColumnWidth(40),
          2: const pw.FixedColumnWidth(40),
          3: const pw.FixedColumnWidth(40),
        },
        border: pw.TableBorder(
           verticalInside: pw.BorderSide(),
           horizontalInside: pw.BorderSide.none, // We handle row borders manually
        ),
        children: rows,
      ),
    );
  }

  pw.Widget _buildCenteredHeader(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7), textAlign: pw.TextAlign.center),
    );
  }

  pw.Widget _buildCenteredCell(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  pw.Widget _buildConsolidatedFooter(
    Evaluation? autoEval,
    Evaluation? gestorEval,
    List<Map<String, dynamic>> questions,
    String requiredType,
  ) {
    // Totals
    double totalMedia = 0;
    final autoRespostas = autoEval?.answers ?? {};
    final gestorRespostas = gestorEval?.answers ?? {};

    // Only count active OPERACIONAL questions? or provided list
    // Assuming passed list is correct context
    for (var q in questions) {
       final id = q['id'] as String;
       if (q['ativo'] == true && q['tipo'] == requiredType) {
          final a = autoRespostas[id] ?? 0;
          final g = gestorRespostas[id] ?? 0;
          totalMedia += (a + g) / 2.0;
       }
    }

    // Concept
    String conceito = 'Insuficiente';
    final points = totalMedia; 
    if (points >= 90) conceito = 'Excelente';
    else if (points >= 70) conceito = 'Bom';
    else if (points >= 60) conceito = 'Regular';
    else if (points >= 50) conceito = 'Recuperável';

    // Obs
    String obs = 'NADA CONSTA';
    if (autoEval?.obs != null && autoEval!.obs!.trim().isNotEmpty) {
      obs = autoEval.obs!;
    } else if (gestorEval?.obs != null && gestorEval!.obs!.trim().isNotEmpty) {
      obs = gestorEval.obs!;
    }

    // Layout: 
    // Left: Flex (Obs)
    // Right: Fixed 120 (40+40+40)
    // Right Block: 
    //   Row 1: Label (80px) | Value (40px) -> Total
    //   Row 2: Label (80px) | Value (40px) -> Conceito
    
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(), right: pw.BorderSide(), bottom: pw.BorderSide())
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
           // OBS (Expanded)
           pw.Expanded(
             child: pw.Container(
               padding: const pw.EdgeInsets.all(5),
               decoration: const pw.BoxDecoration(
                 border: pw.Border(right: pw.BorderSide())
               ),
               constraints: const pw.BoxConstraints(minHeight: 30), // Min height ensuring visibility
               child: pw.Text('Obs.: $obs', style: const pw.TextStyle(fontSize: 8)),
             )
           ),
           
           // TOTALS BLOCK (Fixed 120)
           pw.Container(
             width: 120, // 40 * 3
             child: pw.Column(
               children: [
                  // TOTAL ROW
                  pw.Container(
                    height: 15, // Fixed height to match table rows approx
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide())
                    ),
                    child: pw.Row(
                      children: [
                         // Label 'Total' (Spans 2 cols = 80px)
                         pw.Container(
                           width: 80,
                           alignment: pw.Alignment.center,
                           decoration: const pw.BoxDecoration(
                             border: pw.Border(right: pw.BorderSide())
                           ),
                           child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))
                         ),
                         // Value (40px)
                         pw.Container(
                           width: 40,
                           alignment: pw.Alignment.center,
                           child: pw.Text(totalMedia.toStringAsFixed(1), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))
                         )
                      ]
                    )
                  ),
                  
                  // CONCEITO ROW
                  pw.Container(
                    height: 15,
                    child: pw.Row(
                      children: [
                         // Label 'Conceito' (Spans 2 cols = 80px)
                         pw.Container(
                           width: 80, // Matches above
                           alignment: pw.Alignment.center,
                           decoration: const pw.BoxDecoration(
                             border: pw.Border(right: pw.BorderSide())
                           ),
                           child: pw.Text('Conceito', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))
                         ),
                         // Value (40px)
                         pw.Container(
                           width: 40,
                           alignment: pw.Alignment.center,
                           child: pw.Text(conceito, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)) // Smaller fitting
                         )
                      ]
                    )
                  ),
               ]
             )
           )
        ]
      )
    );
  }

  // Helper removed as it is replaced by _buildConsolidatedSignatures below is correct
  pw.Widget _buildConsolidatedSignatures() {
    // TODO: Implementar assinatura do presidente da comissão
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ASSINATURA DO PRESIDENTE DA COMISSÃO',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Center(
              child: pw.Text(
                '[Assinatura do Presidente]',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}
