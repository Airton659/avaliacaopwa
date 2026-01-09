import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  Employee? selectedEmployee;
  String? draggedEmployeeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Equipes'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final unassignedEmployees = provider.employees
              .where((e) => !e.isManager && e.managerId == null && e.isActive)
              .toList();

          final managers = provider.employees
              .where((e) => e.isManager && e.isActive)
              .toList();

          return Row(
            children: [
              // Coluna Esquerda: Funcionários sem gestor
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.shade300,
                        child: const Text(
                          'Funcionários sem Gestor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: unassignedEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = unassignedEmployees[index];
                            return _buildDraggableEmployee(employee);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Coluna Direita: Gestores e suas equipes
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.shade100,
                        child: const Text(
                          'Gestores e Equipes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: managers.length,
                          itemBuilder: (context, index) {
                            final manager = managers[index];
                            return _buildManagerCard(manager, provider);
                          },
                        ),
                      ),
                      // Botão para adicionar novo gestor
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () => _showPromoteDialog(provider),
                          icon: const Icon(Icons.add),
                          label: const Text('Promover Funcionário a Gestor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDraggableEmployee(Employee employee) {
    return Draggable<Employee>(
      data: employee,
      feedback: Material(
        elevation: 4,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade100,
          child: Text(
            employee.nome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildEmployeeCard(employee),
      ),
      child: _buildEmployeeCard(employee),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(employee.nome),
        subtitle: Text('${employee.funcao} - ${employee.nivel}'),
      ),
    );
  }

  Widget _buildManagerCard(Employee manager, EmployeeProvider provider) {
    final team = provider.employees
        .where((e) => e.managerId == manager.id && e.isActive)
        .toList();

    return DragTarget<Employee>(
      onWillAcceptWithDetails: (details) => details.data.id != manager.id,
      onAcceptWithDetails: (details) {
        provider.assignEmployeeToManager(details.data.id, manager.id);
      },
      builder: (context, candidateData, rejectedData) {
        return Card(
          margin: const EdgeInsets.all(8),
          color: candidateData.isNotEmpty
              ? Colors.blue.shade50
              : Colors.white,
          elevation: candidateData.isNotEmpty ? 8 : 2,
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.supervisor_account, color: Colors.white),
            ),
            title: Text(
              manager.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Equipe: ${team.length} pessoas'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showManagerOptions(manager, team, provider),
            ),
            children: [
              if (team.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum membro na equipe'),
                )
              else
                ...team.map((employee) => ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(employee.nome),
                      subtitle: Text(employee.funcao),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          provider.removeEmployeeFromManager(employee.id);
                        },
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  void _showManagerOptions(
    Employee manager,
    List<Employee> team,
    EmployeeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(manager.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Informações'),
              subtitle: Text(
                'Função: ${manager.funcao}\n'
                'Nível: ${manager.nivel}\n'
                'Equipe: ${team.length} pessoas',
              ),
            ),
          ],
        ),
        actions: [
          if (team.isEmpty)
            TextButton.icon(
              onPressed: () {
                provider.demoteManager(manager.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_downward, color: Colors.red),
              label: const Text(
                'Rebaixar Gestor',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showPromoteDialog(EmployeeProvider provider) {
    final availableEmployees = provider.employees
        .where((e) => !e.isManager && e.isActive)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promover Funcionário a Gestor'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableEmployees.length,
            itemBuilder: (context, index) {
              final employee = availableEmployees[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(employee.nome),
                subtitle: Text(employee.funcao),
                onTap: () {
                  provider.promoteToManager(employee.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
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
}
