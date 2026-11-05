import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'formulario_avaliacao_screen.dart';
import '../utils/password_helper.dart';
import '../utils/situacao_helper.dart';
import '../widgets/multi_situacao_filter.dart';
import '../widgets/multi_tipo_filter.dart';
import '../widgets/expandable_filter_section.dart';

class AutoavaliacaoScreen extends StatefulWidget {
  final String userMatricula;
  final bool isComissao;

  const AutoavaliacaoScreen({
    super.key,
    required this.userMatricula,
    this.isComissao = false,
  });

  @override
  State<AutoavaliacaoScreen> createState() => _AutoavaliacaoScreenState();
}

class _AutoavaliacaoScreenState extends State<AutoavaliacaoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _filtrosSituacao = {};
  Set<String> _filtrosTipo = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autoavaliação - Selecionar Funcionário'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por Nome ou Chapa',
                labelStyle: const TextStyle(fontSize: 18),
                prefixIcon: const Icon(Icons.search, size: 32),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              style: const TextStyle(fontSize: 18),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Lista de funcionários
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('funcionarios').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var employees = snapshot.data!.docs;

                // Filtro por ativo
                employees = employees.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['ativo'] == true;
                }).toList();

                // Coletar situações e tipos únicos dos funcionários ativos
                final situacoesDisponiveis = <String>{};
                final tiposDisponiveis = <String>{};
                for (var doc in employees) {
                  final data = doc.data() as Map<String, dynamic>;
                  final situacao = data['situacao']?.toString() ?? '';
                  final tipo = data['codtipo']?.toString() ?? '';
                  if (situacao.isNotEmpty) {
                    situacoesDisponiveis.add(situacao.toUpperCase());
                  }
                  if (tipo.isNotEmpty) {
                    tiposDisponiveis.add(tipo.toUpperCase());
                  }
                }

                // Filtro de busca
                if (_searchQuery.isNotEmpty) {
                  employees = employees.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nome = (data['nome']?.toString() ?? '').toLowerCase();
                    final chapa = (data['chapa']?.toString() ?? '')
                        .toLowerCase();
                    return nome.contains(_searchQuery) ||
                        chapa.contains(_searchQuery);
                  }).toList();
                }

                // Filtro por situação
                if (_filtrosSituacao.isNotEmpty) {
                  employees = employees.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final situacao = data['situacao']?.toString() ?? '';
                    return _filtrosSituacao.contains(situacao.toUpperCase());
                  }).toList();
                }

                // Filtro por tipo
                if (_filtrosTipo.isNotEmpty) {
                  employees = employees.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final tipo = data['codtipo']?.toString() ?? '';
                    return _filtrosTipo.contains(tipo.toUpperCase());
                  }).toList();
                }

                if (employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Nenhum funcionário encontrado'
                              : 'Nenhum resultado para "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Filtros expansíveis
                    if (situacoesDisponiveis.isNotEmpty ||
                        tiposDisponiveis.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            if (situacoesDisponiveis.isNotEmpty)
                              ExpandableFilterSection(
                                title: 'Filtrar por Situação',
                                count: _filtrosSituacao.length,
                                child: MultiSituacaoFilter(
                                  selectedSituacoes: _filtrosSituacao,
                                  availableSituacoes: situacoesDisponiveis,
                                  onChanged: (newSelection) {
                                    setState(() {
                                      _filtrosSituacao = newSelection;
                                    });
                                  },
                                ),
                              ),
                            if (tiposDisponiveis.isNotEmpty)
                              ExpandableFilterSection(
                                title: 'Filtrar por Tipo',
                                count: _filtrosTipo.length,
                                child: MultiTipoFilter(
                                  selectedTipos: _filtrosTipo,
                                  availableTipos: tiposDisponiveis,
                                  onChanged: (newSelection) {
                                    setState(() {
                                      _filtrosTipo = newSelection;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final doc = employees[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final chapa = doc.id;

                          return _buildEmployeeCard(chapa, data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(String chapa, Map<String, dynamic> data) {
    final nome = data['nome']?.toString() ?? '';
    final funcao = data['funcao']?.toString() ?? '';
    final nivel = data['nivel']?.toString() ?? '';
    final situacao = SituacaoHelper.getDescricaoCompleta(
      data['situacao']?.toString(),
    );
    final isManager = data['isManager'] ?? false;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getAutoavaliacaoInfo(chapa),
      builder: (context, snapshot) {
        final avaliacaoData = snapshot.data;
        final jaAvaliou = avaliacaoData != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: InkWell(
            onTap: () => _showPasswordDialog(chapa, data),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isManager
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        child: Icon(
                          isManager ? Icons.supervisor_account : Icons.person,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                fontSize: 18, // Reduced slightly to help fit
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$funcao - Nível $nivel',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              'Chapa: $chapa',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              situacao,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (jaAvaliou &&
                                avaliacaoData['status'] != null &&
                                avaliacaoData['status'] != 'pendente') ...[
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final status = avaliacaoData['status'];
                                  Color badgeColor;
                                  Color backgroundColor;
                                  IconData icon;
                                  String label;

                                  switch (status) {
                                    case 'em_andamento':
                                      badgeColor = Colors.orange;
                                      backgroundColor = Colors.orange
                                          .withValues(alpha: 0.1);
                                      icon = Icons.edit;
                                      label = 'Em Andamento';
                                      break;
                                    case 'aguardando_assinatura':
                                      badgeColor = Colors.blue;
                                      backgroundColor = Colors.blue.withValues(
                                        alpha: 0.1,
                                      );
                                      icon = Icons.pending;
                                      label = 'Aguardando Assinatura';
                                      break;
                                    case 'concluida':
                                      badgeColor = Colors.green;
                                      backgroundColor = Colors.green.withValues(
                                        alpha: 0.1,
                                      );
                                      icon = Icons.check_circle;
                                      // Para concluída, mostra data e usuário
                                      label =
                                          avaliacaoData['displayInfo'] ??
                                          'Concluído';
                                      break;
                                    default:
                                      return const SizedBox.shrink();
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      border: Border.all(color: badgeColor),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 14, color: badgeColor),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: badgeColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!(jaAvaliou &&
                          avaliacaoData['status'] == 'concluida'))
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue,
                          size: 24,
                        ),
                    ],
                  ),
                  if (jaAvaliou && avaliacaoData['status'] == 'concluida') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.isComissao)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () =>
                                  _confirmarLiberacaoReavaliacao(chapa, data),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Icon(Icons.restore, size: 18),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: () => _showPasswordDialog(chapa, data),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text(
                            'Visualizar',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getAutoavaliacaoInfo(String chapa) async {
    try {
      final configDoc = await _firestore
          .collection('config')
          .doc('general')
          .get();
      final cycle = configDoc.data()?['currentCycle'] ?? '2024/2025';

      final year = cycle.split('/')[0];
      final docId = '${year}_${chapa}_AUTO';

      final doc = await _firestore.collection('evaluations').doc(docId).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;

      // Formatar display info: dd/MM/yyyy - matricula
      String displayInfo = 'Concluído';

      if (data['createdAt'] != null && data['authorMatricula'] != null) {
        final timestamp = data['createdAt'] as Timestamp;
        final date = timestamp.toDate();
        final formattedDate =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        final author = data['authorMatricula'];
        displayInfo = '$formattedDate - $author';
      }

      return {...data, 'displayInfo': displayInfo, 'status': data['status']};
    } catch (e) {
      return null;
    }
  }

  void _showPasswordDialog(String chapa, Map<String, dynamic> data) {
    final passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Senha da Comissão',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite a senha para liberar a avaliação:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: const TextStyle(fontSize: 16),
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                ),
                onSubmitted: (_) async {
                  final valid = await _validatePassword(
                    passwordController.text,
                  );
                  if (valid) {
                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      _navigateToForm(chapa, data);
                    }
                  } else {
                    setState(() {
                      errorMessage = 'Senha incorreta';
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () async {
                final valid = await _validatePassword(passwordController.text);
                if (valid) {
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    _navigateToForm(chapa, data);
                  }
                } else {
                  setState(() {
                    errorMessage = 'Senha incorreta';
                  });
                }
              },
              child: const Text('Confirmar', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _validatePassword(String password) async {
    try {
      final comissaoDoc = await _firestore
          .collection('comissao')
          .doc(widget.userMatricula)
          .get();
      if (!comissaoDoc.exists) return false;

      final senhaComissao = comissaoDoc.data()?['senha'] ?? '';
      return PasswordHelper.checkPassword(password, senhaComissao);
    } catch (e) {
      return false;
    }
  }

  void _navigateToForm(String chapa, Map<String, dynamic> data) {
    final isManager = data['isManager'] ?? false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioAvaliacaoScreen(
          chapa: chapa,
          employeeData: data,
          isAutoavaliacao: true,
          isGerencial: isManager,
          authorMatricula: widget.userMatricula,
        ),
      ),
    ).then((_) {
      // Atualiza a lista quando voltar
      setState(() {});
    });
  }

  Future<void> _confirmarLiberacaoReavaliacao(
    String chapa,
    Map<String, dynamic> data,
  ) async {
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
              Text('Deseja realmente EXCLUIR a avaliação de ${data['nome']}?'),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Liberar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _liberarReavaliacao(chapa);
    }
  }

  Future<void> _liberarReavaliacao(String chapa) async {
    try {
      final configDoc = await _firestore
          .collection('config')
          .doc('general')
          .get();
      final cycle = configDoc.data()?['currentCycle'] ?? '2024/2025';
      final year = cycle.split('/')[0];
      final docId = '${year}_${chapa}_AUTO';

      await _firestore.collection('evaluations').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação liberada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Recarregar lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao liberar avaliação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
