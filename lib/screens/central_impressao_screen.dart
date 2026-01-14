import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';

class CentralImpressaoScreen extends StatelessWidget {
  const CentralImpressaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Central de Impressão'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.print, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('TESTE: Gerar Anexo I (Visual)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: () async {
                final dummyEmployee = Employee(
                  id: '12345',
                  nome: 'João da Silva',
                  admissao: '01/02/2020',
                  funcao: 'Analista de Sistemas',
                  nivel: 'III',
                  faixa: 'A',
                  situacao: 'Ativo',
                  isManager: false,
                );

                await Printing.layoutPdf(
                  onLayout: (format) => PdfService().generateAnexoI(dummyEmployee, null),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
