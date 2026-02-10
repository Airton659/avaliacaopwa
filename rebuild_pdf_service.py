import os

file_path = r'c:\Users\user\Documents\SAD\lib\services\pdf_service.dart'

# The code to append (Corrected strings and indentation)
new_methods = r'''
  Future<Uint8List> generateAnexoXII(
    Employee employee, 
    List<Evaluation> evaluations, 
    int currentCycleYear, 
    {
      CommissionPresident? president,
      String recomendacaoResult = '',
      int? recomendacaoIndex,
    }
  ) async {
    final pdf = pw.Document();
    
    // Calculate Cycle Years
    final startYear = employee.currentTrienniumStart ?? (currentCycleYear - 2);
    final years = [startYear, startYear + 1, startYear + 2];
    
    final Map<int, double?> scores = {};
    for (var year in years) {
       try {
         final eval = evaluations.firstWhere((e) => e.id.startsWith('${year}_'));
         double? score;
         if (eval.answers.isNotEmpty) {
            // Calculate average if not pre-calculated? 
            // Evaluation model usually has answers map.
            // Let's sum values.
            double sum = 0;
            eval.answers.forEach((k, v) {
               sum += (double.tryParse(v.toString()) ?? 0);
            });
            // If the values are directly the score or part of a sum, we assume sum here based on context
            score = sum;
         }
         // Override if manual score exists?
         if (eval.manualScore != null) {
             score = eval.manualScore;
         }
         scores[year] = score;
       } catch (_) {
         scores[year] = null;
       }
    }

    // Calculate Final Mean
    double sum = 0;
    int count = 0;
    scores.forEach((key, value) {
      if (value != null) {
        sum += value;
        count++;
      }
    });
    final mediaFinal = count > 0 ? sum / count : 0.0;

    pw.ImageProvider? presidentSignatureImage;
    if (president?.signatureUrl != null && president!.signatureUrl.isNotEmpty) {
      try {
        presidentSignatureImage = await resolveImage(president.signatureUrl);
      } catch (e) {
        // Fallback
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('Conclusão de Ciclo', null),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('ANEXO XII - TERMO DE CONCLUSÃO DO PROCESSO DE AVALIAÇÃO DE DESEMPENHO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12), textAlign: pw.TextAlign.center)),
              pw.SizedBox(height: 30),
              
              pw.Text(
                'Por este termo, fica concluído o processo de avaliação de desempenho relativo à T.I.A. nº ${employee.id} para todos os fins de direito, conferindo-se ao Empregado o Escore de:',
                style: const pw.TextStyle(fontSize: 12),
                textAlign: pw.TextAlign.justify
              ),
              
              pw.SizedBox(height: 20),
              pw.Text('Notas do triênio:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              // Table of Scores
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: years.map((y) => pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$y', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))))).toList(),
                  ),
                  pw.TableRow(
                     children: years.map((y) {
                       final s = scores[y];
                       return pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(s != null ? s.toStringAsFixed(1) : '-', style: const pw.TextStyle(fontSize: 14))));
                     }).toList(),
                  )
                ]
              ),
              
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Text('Média Final', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Container(
                      width: 80,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(), right: pw.BorderSide(), bottom: pw.BorderSide())),
                      child: pw.Center(child: pw.Text(mediaFinal.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
                    ),
                ])
              ),

              pw.SizedBox(height: 30),
              
              // Result Box
              pw.Row(children: [
                pw.Container(
                  width: 100,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text('Resultado:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                   child: pw.Container(
                     height: 26, 
                     padding: const pw.EdgeInsets.all(5),
                     decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(), right: pw.BorderSide(), bottom: pw.BorderSide())),
                     child: pw.Text(recomendacaoResult),
                   )
                )
              ]),
              
              pw.SizedBox(height: 30),
              pw.Text('RECOMENDA-SE:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              // Recommendations Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {0: const pw.FixedColumnWidth(40)},
                children: [
                  _buildRecommendationRow(0, 'O arquivamento do processo e o registro funcional dos resultados;', recomendacaoIndex),
                  _buildRecommendationRow(1, 'A recuperação assistida do empregado, com perda da progressão;', recomendacaoIndex),
                  _buildRecommendationRow(2, 'A demissão do empregado, por insuficiência de desempenho;', recomendacaoIndex),
                  _buildRecommendationRow(3, 'A progressão horizontal do empregado;', recomendacaoIndex),
                  _buildRecommendationRow(4, 'A possibilidade de progressão vertical do empregado na carreira.', recomendacaoIndex),
                ]
              ),

              pw.Spacer(),
              
              pw.Text('Itabira, ${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} de ${DateTime.now().year}.', textAlign: pw.TextAlign.center),
              
              pw.SizedBox(height: 40),
              
              // Signatures
              pw.Divider(),
              pw.Center(child: pw.Text('Presidente da C.G.C.', style: const pw.TextStyle(fontSize: 10))),
              if (presidentSignatureImage != null)
                 pw.Center(child: pw.Container(height: 40, child: pw.Image(presidentSignatureImage))),
                 
              pw.SizedBox(height: 40),
              pw.Center(child: pw.Text('Ciente em: ____/____/______')),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }

  pw.TableRow _buildRecommendationRow(int index, String text, int? selectedIndex) {
    return pw.TableRow(
      children: [
        pw.Center(child: pw.Text(index == selectedIndex ? 'X' : '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(text)),
      ]
    );
  }
}
'''

try:
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    # Locate the end of the class. 
    # We look for the last method _buildCommissionSignature and its closing brace.
    # We will search from the end backwards until we find "class PdfService" or similar context? 
    # No, risky.
    
    # Start looking from line 1800
    insert_index = -1
    
    for i in range(len(lines) - 1, 0, -1):
        line = lines[i].strip()
        # Find the LAST '}' which should be the class closer IF the file was valid.
        # But file is broken.
        # Let's find "pw.Widget _buildCommissionSignature"
        if "_buildCommissionSignature" in lines[i]:
            # Now find the closing brace of this method.
            # It should be indentation level 2 (approx).
            # We scan forward from here.
            
            # Simple counter approach
            brace_count = 0
            found_start = False
            
            for j in range(i, len(lines)):
                if '{' in lines[j]:
                    brace_count += lines[j].count('{')
                    found_start = True
                
                if '}' in lines[j]:
                    brace_count -= lines[j].count('}')
                
                if found_start and brace_count == 0:
                    # found the closing brace of the method!
                    # The class closing brace should be the next '}'
                    # BUT we want to replace everything after this METHOD with our new code + class closer.
                    insert_index = j + 1
                    break
            break
            
    if insert_index != -1:
        # Keep everything up to the method close
        kept_lines = lines[:insert_index]
        
        # Write NEW file
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(kept_lines)
            f.write('\n')
            f.write(new_methods)
            
        print("File rebuilt successfully.")
    else:
        print("Could not find insertion point.")

except Exception as e:
    print(f"Error: {e}")
