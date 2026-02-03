import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/situacao_helper.dart';
import '../widgets/multi_situacao_filter.dart';
import '../widgets/multi_tipo_filter.dart';
import '../widgets/expandable_filter_section.dart';
import '../utils/password_helper.dart';

class GerenciarComissaoScreen extends StatefulWidget {
  const GerenciarComissaoScreen({super.key});

  @override
  State<GerenciarComissaoScreen> createState() =>
      _GerenciarComissaoScreenState();
}

class _GerenciarComissaoScreenState extends State<GerenciarComissaoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _filtrosSituacao = {};
  Set<String> _filtrosTipo = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gerenciar Comissão',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Configurar Ciclo',
            onPressed: _configurarCiclo,
          ),
        ],
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione funcionários para adicionar à Comissão de Avaliação',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar funcionário',
                    labelStyle: const TextStyle(fontSize: 16),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
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
                  style: const TextStyle(fontSize: 16),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),

            // Dropdown de filtro dinâmico
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('funcionarios').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              // Coletar situações e tipos únicos
              final funcionariosAtivos = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['ativo'] == true;
              }).toList();

              final situacoesDisponiveis = <String>{};
              final tiposDisponiveis = <String>{};

              for (var doc in funcionariosAtivos) {
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

              if (situacoesDisponiveis.isEmpty && tiposDisponiveis.isEmpty)
                return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.deepPurple.shade50,
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
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),

          // Lista de funcionários
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('funcionarios').snapshots(),
              builder: (context, funcionariosSnapshot) {
                if (funcionariosSnapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${funcionariosSnapshot.error}'),
                  );
                }

                if (!funcionariosSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('comissao').snapshots(),
                  builder: (context, comissaoSnapshot) {
                    if (!comissaoSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }


                    // Filtrar apenas funcionários ativos
                    var funcionarios = funcionariosSnapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['ativo'] == true;
                    }).toList();

                    // Criar mapa de comissão PRIMEIRO para usar no filtro depois
                    final comissaoMap = <String, Map<String, dynamic>>{};
                    for (var doc in comissaoSnapshot.data!.docs) {
                      comissaoMap[doc.id] = doc.data() as Map<String, dynamic>;
                    }

                    // Se não houver busca, mostrar APENAS quem já está na comissão
                    if (_searchQuery.isEmpty) {
                      funcionarios = funcionarios.where((doc) {
                        return comissaoMap.containsKey(doc.id);
                      }).toList();
                    }

                    // Coletar situações únicas dos funcionários ativos
                    final situacoesDisponiveis = <String>{};
                    for (var doc in funcionarios) {
                      final data = doc.data() as Map<String, dynamic>;
                      final situacao = data['situacao']?.toString() ?? '';
                      if (situacao.isNotEmpty) {
                        situacoesDisponiveis.add(situacao.toUpperCase());
                      }
                    }

                    // Filtro de busca
                    if (_searchQuery.isNotEmpty) {
                      funcionarios = funcionarios.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nome = (data['nome']?.toString() ?? '').toLowerCase();
                        final chapa = doc.id.toLowerCase();
                        return nome.contains(_searchQuery) || chapa.contains(_searchQuery);
                      }).toList();
                    }

                    // Filtro por situação (multi-seleção)
                    if (_filtrosSituacao.isNotEmpty) {
                      funcionarios = funcionarios.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final situacao = data['situacao']?.toString() ?? '';
                        return _filtrosSituacao.contains(situacao.toUpperCase());
                      }).toList();
                    }

                    // Filtro por tipo (multi-seleção)
                    if (_filtrosTipo.isNotEmpty) {
                      funcionarios = funcionarios.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final tipo = data['codtipo']?.toString() ?? '';
                        return _filtrosTipo.contains(tipo.toUpperCase());
                      }).toList();
                    }

                    // (Mapa já criado acima)

                    if (funcionarios.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum funcionário encontrado',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: funcionarios.length,
                      itemBuilder: (context, index) {
                        final doc = funcionarios[index];
                        final chapa = doc.id;
                        final data = doc.data() as Map<String, dynamic>;
                        final naComissao = comissaoMap.containsKey(chapa);
                        final isSuperAdmin = comissaoMap[chapa]?['isSuperAdmin'] == true;
                        final ativo = naComissao && comissaoMap[chapa]?['ativo'] == true;
                        final isPresident = comissaoMap[chapa]?['isPresident'] == true;

                        return _buildFuncionarioCard(
                          chapa,
                          data,
                          naComissao,
                          isSuperAdmin,
                          isPresident,
                          ativo,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuncionarioCard(
    String chapa,
    Map<String, dynamic> data,
    bool naComissao,
    bool isSuperAdmin,
    bool isPresident,
    bool ativo,
  ) {
    final nome = data['nome']?.toString() ?? '';
    final funcao = data['funcao']?.toString() ?? '';
    final situacao = SituacaoHelper.getDescricaoCompleta(data['situacao']?.toString());

    // Cores e Ícones
    Color cardColor = Colors.white;
    Color iconColor = Colors.blue.shade700;
    Color accentColor = Colors.blue.shade700; // Para textos/bordas
    IconData iconData = Icons.person;

    if (naComissao) {
      if (!ativo && !isSuperAdmin) {
        cardColor = Colors.grey.shade50;
        iconColor = Colors.grey.shade500;
        accentColor = Colors.grey.shade700;
        iconData = Icons.person_off;
      } else if (isSuperAdmin) {
        cardColor = Colors.amber.shade50;
        iconColor = Colors.amber.shade800;
        accentColor = Colors.amber.shade900;
        iconData = Icons.admin_panel_settings;
      } else if (isPresident) {
        cardColor = Colors.indigo.shade50; // COR DISTINTA
        iconColor = Colors.indigo.shade700;
        accentColor = Colors.indigo.shade900;
        iconData = Icons.verified; // Star distinction
      } else {
        // Membro Comum
        cardColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        accentColor = Colors.green.shade900;
        iconData = Icons.verified_user;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: naComissao ? 3 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: naComissao ? BorderSide(color: accentColor.withOpacity(0.3), width: 1) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: iconColor,
                  child: Icon(iconData, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: naComissao ? accentColor : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$funcao • Chapa: $chapa',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                       Row(
                         children: [
                           Expanded(
                             child: Text(
                              situacao,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                                                     ),
                           ),
                         ],
                       ),
                      
                      // Badges
                      if (isSuperAdmin || isPresident || (!ativo && naComissao))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (isSuperAdmin)
                                _buildBadge('SUPER ADMIN', Colors.amber.shade800, Colors.amber.shade100),
                              if (isPresident)
                                _buildBadge('PRESIDENTE', Colors.indigo.shade700, Colors.indigo.shade100),
                              if (!ativo && naComissao && !isSuperAdmin)
                                _buildBadge('DESATIVADO', Colors.grey.shade700, Colors.grey.shade200),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Ações (Barra inferior)
            // Ações (Barra inferior)
            if (naComissao) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   // Promote to President
                   if (!isSuperAdmin && ativo && !isPresident)
                      IconButton(
                        icon: const Icon(Icons.star_border, color: Colors.indigo),
                        tooltip: 'Promover a Presidente',
                        onPressed: () => _definirPresidente(chapa, nome),
                      ),
                   
                   // Edit Password
                   IconButton(
                      icon: const Icon(Icons.lock_outline, color: Colors.blue),
                      tooltip: 'Alterar Senha',
                      onPressed: () => _editarSenha(chapa, nome),
                    ),

                   // Toggle Active
                   if (!isSuperAdmin)
                     Switch(
                       value: ativo,
                       onChanged: (value) => _toggleAtivo(chapa, value),
                       activeColor: Colors.green,
                     ),

                   // Delete
                   if (!isSuperAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remover',
                      onPressed: () => _removerComissao(chapa, nome),
                    ),
                ],
              )
            ] else 
              // Botão Adicionar (Fora da comissão)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _adicionarComissao(chapa, nome),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _definirPresidente(String chapa, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Presidente'),
        content: Text('Deseja promover $nome a Presidente da Comissão?\nIsso removerá o status de presidente de qualquer outro membro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final batch = _firestore.batch();

      // 1. Encontrar e remover presidente atual
      final currentPresidentQuery = await _firestore
          .collection('comissao')
          .where('isPresident', isEqualTo: true)
          .get();

      for (var doc in currentPresidentQuery.docs) {
        batch.update(doc.reference, {'isPresident': false});
      }

      // 2. Definir novo presidente
      final newPresidentRef = _firestore.collection('comissao').doc(chapa);
      batch.update(newPresidentRef, {
        'isPresident': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome é agora o Presidente da Comissão'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao definir presidente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _adicionarComissao(String chapa, String nome) async {
    final senhaController = TextEditingController();

    final senha = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adicionar $nome à Comissão de Avaliação'),
            const SizedBox(height: 16),
            TextField(
              controller: senhaController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, senhaController.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (senha == null || senha.isEmpty) return;

    try {
      await _firestore.collection('comissao').doc(chapa).set({
        'matricula': chapa,
        'senha': PasswordHelper.hashPassword(senha),
        'ativo': true,
        'isSuperAdmin': false,
        'isFirstAccess': true, // Forçar troca de senha no primeiro acesso
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome adicionado à comissão com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editarSenha(String chapa, String nome) async {
    final senhaController = TextEditingController();

    final novaSenha = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alterar senha de $nome'),
            const SizedBox(height: 16),
            TextField(
              controller: senhaController,
              decoration: const InputDecoration(
                labelText: 'Nova Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, senhaController.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (novaSenha == null || novaSenha.isEmpty) return;

    try {
      await _firestore.collection('comissao').doc(chapa).update({
        'senha': PasswordHelper.hashPassword(novaSenha),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha alterada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar senha: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAtivo(String chapa, bool novoValor) async {
    try {
      await _firestore.collection('comissao').doc(chapa).update({
        'ativo': novoValor,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(novoValor ? 'Membro ativado' : 'Membro desativado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removerComissao(String chapa, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: Text('Remover $nome da Comissão de Avaliação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _firestore.collection('comissao').doc(chapa).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome removido da comissão'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _configurarCiclo() async {
    // Buscar ciclo atual
    String cicloAtual = '2026';
    try {
      final doc = await _firestore.collection('config').doc('general').get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('currentCycle')) {
        cicloAtual = doc.data()!['currentCycle'];
      }
    } catch (e) {
      // Ignorar erro e usar padrão
    }

    final cicloController = TextEditingController(text: cicloAtual);

    if (!mounted) return;

    final novoCiclo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Ano de Realização'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defina o ano de realização da avaliação (ex: 2026).\nIsso afetará todas as novas avaliações e os filtros do dashboard.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cicloController,
              decoration: const InputDecoration(
                labelText: 'Ano de Realização',
                hintText: 'AAAA',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, cicloController.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (novoCiclo == null || novoCiclo.isEmpty || novoCiclo == cicloAtual) return;

    try {
      await _firestore.collection('config').doc('general').set({
        'currentCycle': novoCiclo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Ano de realização atualizado para $novoCiclo'),
            backgroundColor: Colors.green,
          ),
        );

        // CHECK FOR AUTOMATIC TRIENNIUM RENEWAL
        await _verificarRenovacaoAutomatica(int.tryParse(cicloAtual) ?? 0, int.tryParse(novoCiclo) ?? 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configuração: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verificarRenovacaoAutomatica(int oldYear, int newYear) async {
      // Logic: If moving from Year X to X+1, check who finished cycle in Year X
      // Finished Cycle condition: (oldYear - startYear) == 2 (aka 3rd year)
      // OR specifically: (oldYear - startYear) >= 2
      
      if (newYear <= oldYear) return; // Only forward changes trigger logic? Or any change? Let's assume forward.
      
      // Query candidates
      final snapshot = await _firestore.collection('funcionarios')
          .get();
      
      final candidates = <String>[];
      
      for (var doc in snapshot.docs) {
          final data = doc.data();
          final start = data['currentTrienniumStart'] as int?;
          if (start == null) continue;

          // If in the old year, they were at Year 3 (End), then in new year they need renewal.
          // Example: Old=2026, Start=2024. Delta = 2. It was their final year.
          // New=2027. We want to update Start to 2027.
          if ((oldYear - start) >= 2) {
             candidates.add(doc.id);
          }
      }

      if (candidates.isEmpty) return;

      if (!mounted) return;

      // Prompt User
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
           title: const Text('Renovação Automática de Triênios'),
           content: Text(
             'Detectamos que ${candidates.length} funcionários encerraram o ciclo trienal em $oldYear.\n\n'
             'Deseja atualizar automaticamente o Início do Triênio deles para $newYear?\n\n'
             'Isso definirá $newYear como o "Ano 1" para esses funcionários.',
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context, false),
               child: const Text('Não, farei manualmente'),
             ),
             ElevatedButton(
               onPressed: () => Navigator.pop(context, true),
               child: const Text('Sim, renovar agora'),
             ),
           ],
        ),
      );

      if (confirm == true) {
         await _executarRenovacaoEmMassa(candidates, newYear);
      }
  }

  Future<void> _executarRenovacaoEmMassa(List<String> ids, int newStartYear) async {
     try {
       final batch = _firestore.batch();
       for (var id in ids) {
         final ref = _firestore.collection('funcionarios').doc(id);
         batch.update(ref, {'currentTrienniumStart': newStartYear});
       }
       await batch.commit();

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${ids.length} triênios renovados com sucesso!'), backgroundColor: Colors.teal),
         );
       }
     } catch (e) {
        if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na renovação em massa: $e'), backgroundColor: Colors.red),
         );
       }
     }
  }
}
