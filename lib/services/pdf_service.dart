import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';

class PdfService {
  Future<Uint8List> generateAnexoI(Employee employee, Evaluation? evaluation, List<Map<String, dynamic>> questions, int cycle) async {
    final pdf = pw.Document();

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
                child: _buildEvaluationMatrix(evaluation, questions),
              ),
              _buildFooter(evaluation, questions),
              _buildSignatures(evaluation, signatureImage),
            ],
          );
        },
      ),
    );

    return pdf.save();
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

  pw.Widget _buildEvaluationMatrix(Evaluation? evaluation, List<Map<String, dynamic>> questions) {
    // Filter only active questions AND type 'OPERACIONAL' for Anexo I
    final activeQuestions = questions.where((q) {
      final isActive = q['ativo'] as bool? ?? false; 
      final type = q['tipo'] as String? ?? ''; 
      return isActive && type == 'OPERACIONAL';
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



  pw.Widget _buildFooter(Evaluation? evaluation, List<Map<String, dynamic>> questions) {
    // Calculate Total Score
    int totalScore = 0;
    if (evaluation != null) {
      final activeQuestions = questions.where((q) {
        final isActive = q['ativo'] as bool? ?? false;
        final type = q['tipo'] as String? ?? '';
        return isActive && type == 'OPERACIONAL';
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

  pw.Widget _buildSignatures(Evaluation? evaluation, pw.ImageProvider? signatureImage) {
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
                   pw.Text('Empregado', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]
          )
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
