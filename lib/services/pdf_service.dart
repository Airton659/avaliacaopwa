import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';

class PdfService {
  Future<Uint8List> generateAnexoI(Employee employee, Evaluation? evaluation) async {
    final pdf = pw.Document();

    // Carregar logo
    final logoImage = await rootBundle.load('assets/images/logo.png');
    final logoProvider = pw.MemoryImage(logoImage.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildTitleTag(),
              pw.SizedBox(height: 5),
              _buildHeader(logoProvider),
              _buildIdentificationBlock(employee),
              _buildFunctionalSituationBlock(employee),
              pw.Expanded(
                child: _buildEvaluationMatrix(evaluation),
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

  pw.Widget _buildTitleTag() {
    return pw.Text(
      'ANEXO I - a ser preenchido pelo próprio empregado que não assume funções gerenciais',
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    );
  }

  pw.Widget _buildHeader(pw.MemoryImage logo) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      margin: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          // Coluna Esquerda
          pw.Expanded(
            flex: 2,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 40,
                        height: 40,
                        child: pw.Image(logo),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          'Empresa de Desenvolvimento de Itabira Ltda.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Processo de Avaliação de Desempenho Individual',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('C.T.E.A. (Condições de Trabalho do Empregado Avaliado)',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ),
          // Coluna Direita (Período)
          pw.Container(
            width: 150,
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide()),
            ),
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              children: [
                pw.Text('Período de Avaliação', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('01/10/2024 a 30/09/2025', style: pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 5),
                pw.Text('Tipo', style: pw.TextStyle(fontSize: 9)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildCheckbox('ADE'),
                    pw.SizedBox(width: 10),
                    _buildCheckbox('ADO', checked: true), // Padrão ADO
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIdentificationBlock(Employee employee) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          // Linha 1
          pw.Row(
            children: [
              _buildField('Empregado:', employee.nome, flex: 3),
              _buildField('Chapa:', employee.id, flex: 1, borderLeft: true),
            ],
          ),
          pw.Divider(height: 1, thickness: 1),
          // Linha 2
          pw.Row(
            children: [
              _buildField('Emprego Público:', employee.funcao, flex: 1),
              _buildField('Data de admissão:', employee.admissao, flex: 1, borderLeft: true),
            ],
          ),
          pw.Divider(height: 1, thickness: 1),
          // Linha 3
          pw.Row(
            children: [
              _buildField('Nível:', employee.nivel, flex: 1),
              _buildField('Escolaridade de Ingresso:', '', flex: 1, borderLeft: true),
            ],
          ),
          pw.Divider(height: 1, thickness: 1),
          // Linha 4
          pw.Row(
            children: [
              _buildField('Grau:', 'I', flex: 1),
              _buildField('Escolaridade Atual:', '', flex: 1, borderLeft: true),
            ],
          ),
          pw.Divider(height: 1, thickness: 1),
          // Linha 5
          pw.Row(
            children: [
              _buildField('Vencimento:', '', flex: 1),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide())),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Text('Ocorrência disciplinar: ', style: pw.TextStyle(fontSize: 9)),
                      pw.Spacer(),
                      _buildCheckbox('SIM'),
                      pw.SizedBox(width: 5),
                      _buildCheckbox('NÃO'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildField(String label, String value, {int flex = 1, bool borderLeft = false}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        decoration: borderLeft ? pw.BoxDecoration(border: pw.Border(left: pw.BorderSide())) : null,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: pw.Row(
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9)),
            pw.SizedBox(width: 5),
            pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFunctionalSituationBlock(Employee employee) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(), right: pw.BorderSide(), bottom: pw.BorderSide()),
      ),
      child: pw.Row(
        children: [
          // Coluna 1
          pw.Container(
            width: 80,
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: pw.Text('Situação funcional /\nExercício:', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9)),
          ),
          pw.Container(width: 1, height: 45, color: PdfColors.black), // Divisoria
          // Coluna 2
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Column(
                children: [
                  _buildCheckboxRow('Emprego Público comissionado:'),
                  _buildCheckboxRow('Disponibilidade:'),
                  _buildCheckboxRow('Desvio de função:'),
                  _buildCheckboxRow('Emprego Público de provimento:'),
                ],
              ),
            ),
          ),
          pw.Container(width: 1, height: 45, color: PdfColors.black), // Divisoria
          // Coluna 3
          pw.Container(
            width: 120,
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
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

  pw.Widget _buildEvaluationMatrix(Evaluation? evaluation) {
    final questions = {
      'I - Fatores comportamentais:': <String>[],
      'I.1 - Discrição:': [
        'I.1.1 - comportamento discreto em suas relações de trabalho;',
        'I.1.2 - discrição em relação a fatos ocorridos no setor de trabalho;',
        'I.1.3 - atitude respeitosa em relação à chefia, a colegas e ao público;',
        'I.1.4 - guarda responsável de documentos e informações sigilosos.'
      ],
      'I.2 - Assiduidade:': [
        'I.2.1 - assiduidade ao trabalho (frequência mínima de 95%);',
        'I.2.2 - pontualidade no cumprimento de horários;',
        'I.2.3 - permanência regular no local de trabalho;',
        'I.2.4 - atenção no exercício das funções.'
      ],
      'I.3 - Disciplina:': [
        'I.3.1 - presteza no cumprimento de ordens;',
        'I.3.2 - administração do tempo e cumprimento de prazos;',
        'I.3.3 - uso adequado de equipamentos e instalações;',
        'I.3.4 - adaptação a trabalhos em equipe;',
        'I.3.5 - comportamento equilibrado no ambiente de trabalho.'
      ],
      'II - Fatores operacionais / Produtividade:': [
        'II.1 - qualidade e exatidão na execução de tarefas;',
        'II.2 - aptidão para as funções do Emprego Público;',
        'II.3 - iniciativa e comportamento produtivo;',
        'II.4 - aproveitamento/racionalização de recursos e processos de trabalho;',
        'II.5 - volume de produção no trabalho sob sua responsabilidade;',
        'II.6 - aproveitamento de oportunidades de capacitação;',
        'II.7 - capacidade para auxiliar outros empregados públicos.'
      ]
    };

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 5),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          // Header Tabela
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 6,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('I - Fatores comportamentais:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                ),
                pw.Container(width: 1, height: 35, color: PdfColors.black),
                pw.Expanded(
                  flex: 4,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text(
                      'Marque a opção que melhor responda ao fator avaliado, sendo 1 – RUIM  2 – REGULAR 3 – BOM 4 – MUITO BOM  5 – ÓTIMO',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...questions.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;
            final List<pw.Widget> widgets = [];
            
            // Se for categoria principal (II), imprime header de seção
            if (category.startsWith('II - ')) {
               widgets.add(
                 pw.Container(
                   decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                   padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                   width: double.infinity,
                   child: pw.Text(category, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                 )
               );
            } 
            // Se for subgrupo (I.*), imprime apenas se não for 'I - Fatores...' (que ja ta no header)
            else if (items.isNotEmpty) {
                 widgets.add(
                 pw.Container(
                   decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                   padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                   width: double.infinity,
                   child: pw.Text(category, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                 )
               );
            }

            for (var item in items) {
              int? score; // Mapeamento futuro
              widgets.add(
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 6,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          child: pw.Text(item, style: pw.TextStyle(fontSize: 8)), // Fonte menor para caber
                        ),
                      ),
                      pw.Container(width: 1, height: 23, color: PdfColors.black), // Altura da linha
                      pw.Expanded(
                        flex: 4,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                          children: [1, 2, 3, 4, 5].map((val) => 
                            pw.Row(
                                children: [
                                    pw.Text("(", style: pw.TextStyle(fontSize: 8)),
                                    pw.SizedBox(width: 2),
                                    pw.Text(score == val ? "X" : " ", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                    pw.SizedBox(width: 2),
                                    pw.Text(") $val", style: pw.TextStyle(fontSize: 8)),
                                ]
                            )
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                )
              );
            }
            return pw.Column(children: widgets);
          }).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 5),
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
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Column(
              children: [
                   pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                          pw.Text('Itabira, em ____ de _______________ de 20__', style: pw.TextStyle(fontSize: 10)),
                      ]
                   ),
                   pw.SizedBox(height: 15),
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
