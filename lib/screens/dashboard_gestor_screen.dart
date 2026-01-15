import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import 'formulario_avaliacao_screen.dart';
import 'assinatura_segura_screen.dart';
import 'package:intl/intl.dart';

class DashboardGestorScreen extends StatefulWidget {
  final String userMatricula;
  final String userName;

  const DashboardGestorScreen({
    super.key,
    required this.userMatricula,
    required this.userName,
  });

  @override
  State<DashboardGestorScreen> createState() => _DashboardGestorScreenState();
}

class _DashboardGestorScreenState extends State<DashboardGestorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _selectedEvaluations = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Equipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('config').doc('general').get(),
        builder: (context, configSnapshot) {
          if (!configSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ciclo = configSnapshot.data?.get('currentCycle') ?? '2026';
          final ano = ciclo;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('funcionarios')
                .where('managerId', isEqualTo: widget.userMatricula)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final team = snapshot.data!.docs;

              if (team.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum funcionário encontrado na sua equipe.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: team.length,
                      itemBuilder: (context, index) {
                        final doc = team[index];
                        final employeeData = doc.data() as Map<String, dynamic>;
                        final employeeId = doc.id;

                        // Buscar avaliação deste funcionário (se houver) para o ano configurado
                        return StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('evaluations')
                              .where('employeeId', isEqualTo: employeeId)
                              .where('ano', isEqualTo: ano) // Filtro dinâmico
                              .limit(1)
                              .snapshots(),
                          builder: (context, evalSnapshot) {
                            String status = 'pendente';
                            String? evalId;
                            Map<String, dynamic>? evalData;

                            if (evalSnapshot.hasData &&
                                evalSnapshot.data!.docs.isNotEmpty) {
                              final evalDoc = evalSnapshot.data!.docs.first;
                              evalData = evalDoc.data() as Map<String, dynamic>;
                              status = evalData['status'] ?? 'pendente';
                              evalId = evalDoc.id;
                            }

                            final isReadyToSign =
                                status == 'aguardando_assinatura';
                            final isSelected = evalId != null
                                ? _selectedEvaluations.contains(evalId)
                                : false;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: isReadyToSign ? Colors.blue.shade50 : null,
                              child: ListTile(
                                leading: Checkbox(
                                  value: isSelected,
                                  onChanged: isReadyToSign
                                      ? (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedEvaluations.add(evalId!);
                                            } else {
                                              _selectedEvaluations
                                                  .remove(evalId!);
                                            }
                                          });
                                        }
                                      : null, // Checkbox visível mas desabilitado
                                ),
                                title: Text(employeeData['nome'] ?? 'Sem Nome'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status: ${status.toUpperCase()}'),
                                    if (evalData != null && evalData['updatedAt'] != null)
                                      Text(
                                        'Data de Avaliação: ${DateFormat('dd/MM/yyyy').format((evalData['updatedAt'] as Timestamp).toDate())}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  child: Text(status == 'concluida'
                                      ? 'Visualizar'
                                      : 'Avaliar'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FormularioAvaliacaoScreen(
                                          chapa: employeeId,
                                          employeeData: employeeData,
                                          authorMatricula: widget.userMatricula,
                                          isGerencial: false,
                                          isAutoavaliacao: false,
                                          allowSaveWithoutSignature: true,
                                        ),
                                      ),
                                    ).then((value) {
                                      // Recarregar se necessário (Stream cuida disso)
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_selectedEvaluations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      color: Colors.white,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified_user),
                        label: Text(
                            'Assinar ${_selectedEvaluations.length} Selecionados'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: _assinarEmLote,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _assinarEmLote() async {
    if (_selectedEvaluations.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssinaturaSeguraScreen(
          evaluationIds: _selectedEvaluations.toList(),
          userId: widget.userMatricula,
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
          _selectedEvaluations.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliações assinadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
