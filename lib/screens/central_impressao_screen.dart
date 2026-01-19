import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_service.dart';
import '../services/firebase_service.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';
import '../models/question.dart';

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
                try {
                  final firebaseService = FirebaseService();
                  
                  // 1. Buscar formulário de perguntas
                  final questionsObjs = await firebaseService.getQuestions();
                  final List<Map<String, dynamic>> questionsMap = questionsObjs.map((q) {
                    final data = q.toFirestore();
                    data['id'] = q.id;
                    return data;
                  }).toList();
                  
                  if (!context.mounted) return;

                  // 2. Buscar funcionário 03308
                  final employee = await firebaseService.getEmployeeById('03308');
                  
                  if (!context.mounted) return;

                  if (employee == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funcionário 03308 não encontrado')),
                    );
                    return;
                  }

                  // 3. Buscar avaliação (Dinâmico)
                  // Buscar ciclo atual da configuração
                  final configSnapshot = await FirebaseFirestore.instance.collection('config').doc('general').get();
                  final currentCycleStr = configSnapshot.data()?['currentCycle']?.toString() ?? DateTime.now().year.toString();
                  final currentCycle = int.tryParse(currentCycleStr) ?? DateTime.now().year;

                  final evaluations = await firebaseService.getEmployeeEvaluations(employee.id, currentCycle);
                  // Pega a primeira avaliação encontrada ou null
                  final evaluation = evaluations.isNotEmpty ? evaluations.first : null;

                  if (!context.mounted) return;

                  await Printing.layoutPdf(
                    onLayout: (format) => PdfService().generateAnexoI(employee, evaluation, questionsMap, currentCycle),
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
