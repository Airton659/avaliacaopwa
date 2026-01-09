import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../models/evaluation_type.dart';
import '../providers/employee_provider.dart';
import 'evaluation_form_screen.dart';
import 'manager_evaluation_flow_screen.dart';

class EvaluationSelectorScreen extends StatefulWidget {
  const EvaluationSelectorScreen({super.key});

  @override
  State<EvaluationSelectorScreen> createState() =>
      _EvaluationSelectorScreenState();
}

class _EvaluationSelectorScreenState extends State<EvaluationSelectorScreen> {
  String _searchQuery = '';
  bool _showOnlyManagers = false;

  @override
  void initState() {
    super.initState();
    context.read<EmployeeProvider>().loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Funcionário'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildEmployeeList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar Funcionário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Mostrar apenas Gestores'),
              value: _showOnlyManagers,
              onChanged: (value) {
                setState(() {
                  _showOnlyManagers = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Consumer<EmployeeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var employees = provider.employees.where((e) => e.isActive).toList();

        if (_showOnlyManagers) {
          employees = employees.where((e) => e.isManager).toList();
        }

        if (_searchQuery.isNotEmpty) {
          employees = employees.where((e) {
            return e.nome.toLowerCase().contains(_searchQuery) ||
                e.id.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (employees.isEmpty) {
          return const Center(
            child: Text('Nenhum funcionário encontrado'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return _buildEmployeeCard(employee);
          },
        );
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              employee.isManager ? Colors.blue : Colors.grey.shade400,
          child: Icon(
            employee.isManager ? Icons.supervisor_account : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          employee.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Chapa: ${employee.id} | ${employee.funcao} - ${employee.nivel}',
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _showEvaluationTypeDialog(employee),
      ),
    );
  }

  void _showEvaluationTypeDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Avaliação - ${employee.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment_ind, color: Colors.blue),
              title: const Text('Autoavaliação'),
              onTap: () {
                Navigator.pop(context);
                _startAutoEvaluation(employee);
              },
            ),
            if (employee.isManager)
              ListTile(
                leading: const Icon(Icons.groups, color: Colors.green),
                title: const Text('Avaliar Equipe'),
                onTap: () {
                  Navigator.pop(context);
                  _startManagerEvaluation(employee);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _startAutoEvaluation(Employee employee) {
    final evaluationType = employee.isManager
        ? EvaluationType.autoGerencial
        : EvaluationType.autoOperacional;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationFormScreen(
          employee: employee,
          evaluationType: evaluationType,
          year: DateTime.now().year,
        ),
      ),
    );
  }

  void _startManagerEvaluation(Employee manager) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerEvaluationFlowScreen(manager: manager),
      ),
    );
  }
}
