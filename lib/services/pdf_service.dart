import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';

class PdfService {
  Future<Uint8List> generateAnexoI(Employee employee, Evaluation? evaluation, List<dynamic> questions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlock(employee),
              pw.Expanded(
                child: _buildEvaluationMatrix(evaluation, questions),
              ),
              _buildFooter(),
              _buildSignatures(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
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
                    pw.Text('01/10/2024 a 30/09/2025', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Text('Tipo', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _buildCheckbox('ADE'),
                        pw.SizedBox(width: 15),
                        _buildCheckbox('ADO', checked: true),
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
                  _buildCellContent('Vencimento:', employee.vencimento != null ? 'R\$ ${employee.vencimento!.toStringAsFixed(2)}' : ''),
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

  pw.Widget _buildFunctionalSituationBlock(Employee employee) {
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
                        _buildCheckbox('SIM'),
                        pw.SizedBox(width: 10),
                        _buildCheckbox('NÃO'),
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
                    _buildCheckboxRow('Emprego Público comissionado:'),
                    _buildCheckboxRow('Disponibilidade:'),
                    _buildCheckboxRow('Desvio de função:'),
                    _buildCheckboxRow('Emprego Público de provimento:'),
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
                        _buildCheckbox('SIM'),
                        pw.SizedBox(width: 10),
                        _buildCheckbox('NÃO'),
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

  pw.Widget _buildCheckboxRow(String text) {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 8))),
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        ),
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

  pw.Widget _buildEvaluationMatrix(Evaluation? evaluation, List<dynamic> questions) {
    // Filter only active questions
    final activeQuestions = questions.where((q) => q['ativo'] == true).toList();
    
    // Sort by ordem
    activeQuestions.sort((a, b) => (a['ordem'] as int).compareTo(b['ordem'] as int));
    
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
      grouped[secao]![subsecao]!.add(q as Map<String, dynamic>);
    }

    final List<pw.TableRow> rows = [];
    int questionIndex = 0;
    final totalQuestions = activeQuestions.length;
    
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
        
        final perguntas = subsecoes[subsecao]!;
        
        for (int i = 0; i < perguntas.length; i++) {
          final pergunta = perguntas[i];
          final texto = pergunta['pergunta'] as String;
          final questionId = 'q$questionIndex';
          questionIndex++;
          
          final isLast = questionIndex == totalQuestions;
          
          rows.add(_buildQuestionTableRow(texto, _getScore(evaluation, questionId), !isLast));
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
          0: const pw.FlexColumnWidth(6),
          1: const pw.FlexColumnWidth(4),
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
            ? pw.Text('( X ) $score', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))
            : pw.Text('', style: pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }



  pw.Widget _buildFooter() {
    return pw.Container(
      child: pw.Row(
        children: [
          // Obs
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              height: 40,
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text('Obs.:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ),
          // Total/Conceito
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              children: [
                pw.Container(
                  height: 20,
                   decoration: pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(), right: pw.BorderSide(), bottom: pw.BorderSide())
                   ),
                   padding: const pw.EdgeInsets.only(left: 5),
                   alignment: pw.Alignment.centerLeft,
                   child: pw.Text('Total', style: pw.TextStyle(fontSize: 9)),
                ),
                 pw.Container(
                  height: 20,
                   decoration: pw.BoxDecoration(
                      border: pw.Border(right: pw.BorderSide(), bottom: pw.BorderSide())
                   ),
                   padding: const pw.EdgeInsets.only(left: 5),
                   alignment: pw.Alignment.centerLeft,
                   child: pw.Text('Conceito', style: pw.TextStyle(fontSize: 9)),
                )
              ]
            )
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatures() {
      return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 40),
          child: pw.Column(
              children: [
                   pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                          pw.Text('Itabira, em ____ de _______________ de 20__', style: pw.TextStyle(fontSize: 10)),
                      ]
                   ),
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
}
