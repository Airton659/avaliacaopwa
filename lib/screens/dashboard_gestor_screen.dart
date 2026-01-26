import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import 'formulario_avaliacao_screen.dart';
import 'assinatura_segura_screen.dart';
import 'package:intl/intl.dart';
import '../utils/password_helper.dart';
import 'trocar_senha_screen.dart';
import 'signature_registration_screen.dart';

class DashboardGestorScreen extends StatefulWidget {
  final String userMatricula;
  final String userName;
  final bool isComissao;
  final String? loggedUserMatricula;

  const DashboardGestorScreen({
    super.key,
    required this.userMatricula,
    required this.userName,
    this.isComissao = false,
    this.loggedUserMatricula,
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sair') {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              } else if (value == 'senha') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrocarSenhaScreen(
                      userMatricula: widget.userMatricula,
                      collection: 'funcionarios', // Gestor é funcionario
                      userName: widget.userName,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'senha',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Alterar Senha'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'sair',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sair'),
                    ],
                  ),
                ),
              ];
            },
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
                  // PRESIDENTE: Botão de Registrar Assinatura
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('comissao').doc(widget.userMatricula).snapshots(),
                    builder: (context, comissaoSnapshot) {
                      if (!comissaoSnapshot.hasData) return const SizedBox.shrink();
                      final data = comissaoSnapshot.data!.data() as Map<String, dynamic>?;
                      final isPresident = data?['isPresident'] == true;

                      if (!isPresident) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignatureRegistrationScreen(userId: widget.userMatricula),
                                ),
                              );
                          },
                          icon: const Icon(Icons.edit_document),
                          label: const Text('REGISTRAR/ATUALIZAR ASSINATURA OFICIAL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            elevation: 4,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: team.length,
                      itemBuilder: (context, index) {
                        final doc = team[index];
                        final employeeData = doc.data() as Map<String, dynamic>;
                        final employeeId = doc.id;

                        // Buscar avaliação deste funcionário (se houver) para o ano configurado
                        // FIX: Target specifically the GESTOR evaluation document
                        final evalDocId = '${ano}_${employeeId}_GESTOR';
                        
                        return StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('evaluations')
                              .doc(evalDocId)
                              .snapshots(),
                          builder: (context, evalSnapshot) {
                            String status = 'pendente';
                            String? evalId;
                            Map<String, dynamic>? evalData;

                            if (evalSnapshot.hasData && evalSnapshot.data!.exists) {
                              final evalDoc = evalSnapshot.data!;
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.isComissao && status != 'pendente')
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: ElevatedButton(
                                            onPressed: () => _confirmarLiberacaoReavaliacao(evalId!, employeeData['nome']),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange.shade700,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              minimumSize: const Size(0, 36),
                                            ),
                                            child: const Icon(Icons.restore, size: 18),
                                          ),
                                        ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(status == 'concluida'
                                            ? 'Visualizar'
                                            : 'Avaliar'),
                                        onPressed: () {
                                          if (status != 'concluida' && widget.isComissao) {
                                            _verificarSenhaParaAvaliar(employeeId, employeeData);
                                          } else {
                                            _navegarParaAvaliacao(employeeId, employeeData);
                                          }
                                        },
                                      ),
                                    ],
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

  Future<void> _confirmarLiberacaoReavaliacao(String evalId, String empName) async {
    final passwordController = TextEditingController();
    String? errorMessage;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirmar Liberação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Deseja realmente EXCLUIR a avaliação de $empName?'),
              const SizedBox(height: 10),
              const Text(
                'Esta ação não pode ser desfeita. Digite sua senha para confirmar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Sua Senha',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final valid = await _validatePassword(passwordController.text);
                if (valid) {
                  if (context.mounted) Navigator.pop(dialogContext, true);
                } else {
                  setState(() {
                    errorMessage = 'Senha incorreta';
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Liberar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _liberarReavaliacao(evalId);
    }
  }

  Future<void> _verificarSenhaParaAvaliar(String employeeId, Map<String, dynamic> employeeData) async {
    final authorized = await _solicitarSenha();
    if (authorized) {
      _navegarParaAvaliacao(employeeId, employeeData);
    }
  }

  void _navegarParaAvaliacao(String employeeId, Map<String, dynamic> employeeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioAvaliacaoScreen(
          chapa: employeeId,
          employeeData: employeeData,
          authorMatricula: widget.userMatricula, // Manager is Author
          isGerencial: employeeData['isManager'] ?? false,
          isAutoavaliacao: false,
          allowSaveWithoutSignature: true,
        ),
      ),
    ).then((value) {
      // Recarregar se necessário
    });
  }

  Future<bool> _solicitarSenha() async {
    if (widget.loggedUserMatricula == null) return false;

    final passwordController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirmação de Segurança'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite sua senha para continuar:'),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final valid = await _validatePassword(passwordController.text);
                if (valid) {
                  if (context.mounted) Navigator.pop(dialogContext, true);
                } else {
                  setState(() {
                    errorMessage = 'Senha incorreta';
                  });
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  Future<bool> _validatePassword(String password) async {
    try {
      final doc = await _firestore.collection('comissao').doc(widget.loggedUserMatricula).get();
      if (!doc.exists) return false;
      return PasswordHelper.checkPassword(password, doc.data()?['senha']);
    } catch (e) {
      return false;
    }
  }

  Future<void> _liberarReavaliacao(String evalId) async {
    try {
      await _firestore.collection('evaluations').doc(evalId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação liberada com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao liberar avaliação: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
