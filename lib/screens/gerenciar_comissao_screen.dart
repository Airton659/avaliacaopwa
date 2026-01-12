import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/situacao_helper.dart';

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
  String? _filtroSituacao;

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

          // Dropdown de filtro dinâmico (renderizado após coletar situações)
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('funcionarios').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              // Coletar situações únicas
              final funcionariosAtivos = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['ativo'] == true;
              }).toList();

              final situacoesDisponiveis = <String>{};
              for (var doc in funcionariosAtivos) {
                final data = doc.data() as Map<String, dynamic>;
                final situacao = data['situacao']?.toString() ?? '';
                if (situacao.isNotEmpty) {
                  situacoesDisponiveis.add(situacao.toUpperCase());
                }
              }

              if (situacoesDisponiveis.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                color: Colors.deepPurple.shade50,
                child: DropdownButtonFormField<String>(
                  value: _filtroSituacao,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Situação',
                    labelStyle: TextStyle(fontSize: 16),
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...situacoesDisponiveis.map((situacao) {
                      final descricao = SituacaoHelper.situacoes[situacao] ?? situacao;
                      return DropdownMenuItem<String>(
                        value: situacao,
                        child: Text('$situacao - $descricao'),
                      );
                    }).toList()..sort((a, b) => a.value!.compareTo(b.value!)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtroSituacao = value;
                    });
                  },
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

                    // Filtro por situação
                    if (_filtroSituacao != null) {
                      funcionarios = funcionarios.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final situacao = data['situacao']?.toString() ?? '';
                        return situacao.toUpperCase() == _filtroSituacao;
                      }).toList();
                    }

                    // Criar mapa de comissão
                    final comissaoMap = <String, Map<String, dynamic>>{};
                    for (var doc in comissaoSnapshot.data!.docs) {
                      comissaoMap[doc.id] = doc.data() as Map<String, dynamic>;
                    }

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

                        return _buildFuncionarioCard(
                          chapa,
                          data,
                          naComissao,
                          isSuperAdmin,
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
    bool ativo,
  ) {
    final nome = data['nome']?.toString() ?? '';
    final funcao = data['funcao']?.toString() ?? '';
    final situacao = SituacaoHelper.getDescricaoCompleta(data['situacao']?.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: naComissao ? 4 : 2,
      color: naComissao
          ? (isSuperAdmin
              ? Colors.amber.shade50
              : ativo
                  ? Colors.green.shade50
                  : Colors.grey.shade50)
          : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: naComissao
              ? (isSuperAdmin
                  ? Colors.amber.shade700
                  : ativo
                      ? Colors.green.shade700
                      : Colors.grey.shade500)
              : Colors.blue.shade700,
          child: Icon(
            isSuperAdmin
                ? Icons.admin_panel_settings
                : naComissao
                    ? Icons.verified_user
                    : Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nome,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chapa: $chapa',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                funcao,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                situacao,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isSuperAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SUPER ADMIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        trailing: naComissao
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!ativo && !isSuperAdmin)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: const Text(
                              'DESATIVADO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.grey.shade600,
                          ),
                        ),
                      if (!isSuperAdmin)
                        Switch(
                          value: ativo,
                          onChanged: (value) => _toggleAtivo(chapa, value),
                          activeColor: Colors.green,
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar senha',
                        onPressed: () => _editarSenha(chapa, nome),
                      ),
                      if (!isSuperAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Remover da comissão',
                          onPressed: () => _removerComissao(chapa, nome),
                        ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: () => _adicionarComissao(chapa, nome),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
      ),
    );
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
        'senha': senha,
        'ativo': true,
        'isSuperAdmin': false,
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
        'senha': novaSenha,
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
}
