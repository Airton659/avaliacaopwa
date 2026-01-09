import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../models/evaluation_type.dart';
import '../providers/employee_provider.dart';
import 'evaluation_form_screen.dart';

class ManagerEvaluationFlowScreen extends StatefulWidget {
  final Employee manager;

  const ManagerEvaluationFlowScreen({
    super.key,
    required this.manager,
  });

  @override
  State<ManagerEvaluationFlowScreen> createState() =>
      _ManagerEvaluationFlowScreenState();
}

class _ManagerEvaluationFlowScreenState
    extends State<ManagerEvaluationFlowScreen> {
  List<Employee> _team = [];
  int _currentIndex = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final provider = context.read<EmployeeProvider>();
    await provider.loadEmployees();

    setState(() {
      _team = provider.employees
          .where((e) => e.managerId == widget.manager.id && e.isActive)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_team.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Avaliar Equipe'),
          backgroundColor: Colors.blue.shade700,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Nenhum membro na equipe',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (_isCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Avaliação Concluída'),
          backgroundColor: Colors.green,
        ),
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
                'Todas as avaliações foram concluídas!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Atenção'),
            content: const Text(
              'Tem certeza que deseja sair? O progresso será perdido.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Avaliando ${_team[_currentIndex].nome} (${_currentIndex + 1}/${_team.length})',
          ),
          backgroundColor: Colors.blue.shade700,
        ),
        body: EvaluationFormScreen(
          employee: _team[_currentIndex],
          evaluationType: _team[_currentIndex].isManager
              ? EvaluationType.gestorGerencial
              : EvaluationType.gestorOperacional,
          year: DateTime.now().year,
        ),
        bottomNavigationBar: _buildProgressBar(),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade700,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _team.length,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Progresso: ${_currentIndex + 1} de ${_team.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
