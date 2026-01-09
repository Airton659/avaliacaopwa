import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestaoEquipesScreen extends StatefulWidget {
  const GestaoEquipesScreen({super.key});

  @override
  State<GestaoEquipesScreen> createState() => _GestaoEquipesScreenState();
}

class _GestaoEquipesScreenState extends State<GestaoEquipesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Equipes'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('employees')
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs;

          // Separa funcionários sem gestor e gestores
          final semGestor = employees.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['managerId'] == null && data['isManager'] != true;
          }).toList();

          final gestores = employees.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isManager'] == true;
          }).toList();

          return Row(
            children: [
              // COLUNA ESQUERDA: Funcionários sem gestor
              Expanded(
                child: Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.shade300,
                        child: const Text(
                          'FUNCIONÁRIOS SEM GESTOR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: semGestor.length,
                          itemBuilder: (context, index) {
                            final doc = semGestor[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildFuncionarioCard(doc.id, data);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // COLUNA DIREITA: Gestores e Equipes
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue.shade100,
                        child: const Text(
                          'GESTORES E EQUIPES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: gestores.length,
                          itemBuilder: (context, index) {
                            final doc = gestores[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildGestorBox(doc.id, data, employees);
                          },
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

  Widget _buildFuncionarioCard(String chapa, Map<String, dynamic> data) {
    return Draggable<String>(
      data: chapa,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nome'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data['funcao'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(data, false),
      ),
      child: _buildCardContent(data, false),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> data, bool isGestor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGestor ? Colors.blue : Colors.grey,
          child: Icon(
            isGestor ? Icons.supervisor_account : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          data['nome'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(data['funcao'] ?? ''),
        trailing: isGestor
            ? null
            : IconButton(
                icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                tooltip: 'Promover a Gestor',
                onPressed: () => _promoverGestor(data['chapa']),
              ),
      ),
    );
  }

  Widget _buildGestorBox(
    String gestorChapa,
    Map<String, dynamic> gestorData,
    List<QueryDocumentSnapshot> allEmployees,
  ) {
    // Busca subordinados
    final subordinados = allEmployees.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['managerId'] == gestorChapa;
    }).toList();

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        _atribuirSubordinado(details.data, gestorChapa);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: isHovering ? 8 : 2,
          color: isHovering ? Colors.blue.shade50 : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do Gestor
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.supervisor_account,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gestorData['nome'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            gestorData['funcao'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subordinados.isEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        tooltip: 'Rebaixar Gestor',
                        onPressed: () => _rebaixarGestor(gestorChapa),
                      ),
                  ],
                ),
              ),
              // Lista de Subordinados
              Container(
                padding: const EdgeInsets.all(8),
                child: subordinados.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Arraste funcionários aqui',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: subordinados.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(data['nome'] ?? ''),
                            subtitle: Text(data['funcao'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              tooltip: 'Remover da equipe',
                              onPressed: () => _removerSubordinado(doc.id),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promoverGestor(String chapa) async {
    try {
      await _firestore.collection('employees').doc(chapa).update({
        'isManager': true,
        'managerId': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário promovido a Gestor')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rebaixarGestor(String chapa) async {
    try {
      await _firestore.collection('employees').doc(chapa).update({
        'isManager': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gestor rebaixado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _atribuirSubordinado(String chapaSubordinado, String chapaGestor) async {
    try {
      await _firestore.collection('employees').doc(chapaSubordinado).update({
        'managerId': chapaGestor,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário atribuído à equipe')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removerSubordinado(String chapa) async {
    try {
      await _firestore.collection('employees').doc(chapa).update({
        'managerId': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário removido da equipe')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
