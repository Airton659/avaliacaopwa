import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../models/evaluation.dart';
import '../models/evaluation_type.dart';
import '../models/employee_snapshot.dart';
import '../providers/evaluation_provider.dart';

class EvaluationFormScreen extends StatefulWidget {
  final Employee employee;
  final EvaluationType evaluationType;
  final int year;

  const EvaluationFormScreen({
    super.key,
    required this.employee,
    required this.evaluationType,
    required this.year,
  });

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final Map<String, int> _answers = {};
  final TextEditingController _obsController = TextEditingController();
  bool _isCompleted = false;

  List<String> get _questions {
    // Perguntas para Operacional (Anexos I e II)
    final operacionalQuestions = [
      'q1: Conhecimento técnico',
      'q2: Qualidade do trabalho',
      'q3: Produtividade',
      'q4: Iniciativa',
      'q5: Comprometimento',
      'q6: Trabalho em equipe',
      'q7: Pontualidade',
      'q8: Assiduidade',
    ];

    // Perguntas para Gerencial (Anexos IV e V)
    final gerencialQuestions = [
      'q1: Liderança',
      'q2: Gestão de pessoas',
      'q3: Planejamento estratégico',
      'q4: Tomada de decisão',
      'q5: Visão sistêmica',
      'q6: Comunicação',
      'q7: Gestão de resultados',
      'q8: Inovação',
      'q9: Desenvolvimento da equipe',
      'q10: Relacionamento interpessoal',
    ];

    switch (widget.evaluationType) {
      case EvaluationType.autoOperacional:
      case EvaluationType.gestorOperacional:
        return operacionalQuestions;
      case EvaluationType.autoGerencial:
      case EvaluationType.gestorGerencial:
        return gerencialQuestions;
      default:
        return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnswers();
  }

  void _initializeAnswers() {
    for (final question in _questions) {
      final key = question.split(':')[0];
      _answers[key] = 1; // Nota mínima inicial
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Avaliação concluída!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evaluationType.label),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmployeeInfo(),
            const SizedBox(height: 32),
            const Text(
              'Avaliação de Desempenho',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilize a escala de 1 a 5 para avaliar cada competência:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildScaleLegend(),
            const SizedBox(height: 32),
            ..._questions.map((question) => _buildQuestionCard(question)),
            const SizedBox(height: 32),
            _buildObservationsField(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Funcionário: ${widget.employee.nome}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Função: ${widget.employee.funcao}'),
            Text('Nível: ${widget.employee.nivel}'),
            Text('Faixa: ${widget.employee.faixa}'),
            Text('Admissão: ${widget.employee.admissao}'),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleLegend() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escala de Avaliação:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(1, 'Insuficiente', Colors.red),
            _buildLegendItem(2, 'Regular', Colors.orange),
            _buildLegendItem(3, 'Bom', Colors.yellow.shade700),
            _buildLegendItem(4, 'Muito Bom', Colors.lightGreen),
            _buildLegendItem(5, 'Excelente', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(int value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    final parts = question.split(':');
    final key = parts[0];
    final text = parts[1].trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final value = index + 1;
                final isSelected = _answers[key] == value;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _answers[key] = value;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getColorForValue(value)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForValue(int value) {
    switch (value) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildObservationsField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observações (Opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _obsController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Digite aqui suas observações sobre a avaliação...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _submitEvaluation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: const Text('Concluir Avaliação'),
      ),
    );
  }

  Future<void> _submitEvaluation() async {
    final evaluation = Evaluation(
      id: Evaluation.generateId(
        widget.year,
        widget.employee.id,
        widget.evaluationType,
      ),
      year: widget.year,
      type: widget.evaluationType,
      answers: _answers,
      obs: _obsController.text.isEmpty ? null : _obsController.text,
      employeeSnapshot: EmployeeSnapshot.fromEmployee(widget.employee),
    );

    try {
      await context.read<EvaluationProvider>().saveEvaluation(evaluation);

      setState(() {
        _isCompleted = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar avaliação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }
}
