import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigMenuScreen extends StatefulWidget {
  const ConfigMenuScreen({super.key});

  @override
  State<ConfigMenuScreen> createState() => _ConfigMenuScreenState();
}

class _ConfigMenuScreenState extends State<ConfigMenuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _filtro = '';
  String _tipoSelecionado = 'OPERACIONAL'; // OPERACIONAL ou GERENCIAL

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gerenciar Perguntas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 32),
            tooltip: 'Adicionar Pergunta',
            onPressed: () => _abrirModalPergunta(null),
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de Tipo
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                // Botões de tipo
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _tipoSelecionado = 'OPERACIONAL';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoSelecionado == 'OPERACIONAL'
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                          foregroundColor: _tipoSelecionado == 'OPERACIONAL'
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'OPERACIONAL',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _tipoSelecionado = 'GERENCIAL';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tipoSelecionado == 'GERENCIAL'
                              ? Colors.purple.shade700
                              : Colors.grey.shade300,
                          foregroundColor: _tipoSelecionado == 'GERENCIAL'
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'GERENCIAL',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Campo de busca
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _filtro = value;
                    });
                  },
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Buscar pergunta...',
                    hintStyle: const TextStyle(fontSize: 16),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de perguntas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('questions')
                  .where('tipo', isEqualTo: _tipoSelecionado)
                  .orderBy('ordem')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var perguntas = snapshot.data!.docs;

                // Filtrar perguntas
                if (_filtro.isNotEmpty) {
                  perguntas = perguntas.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final pergunta = (data['pergunta'] ?? '').toString().toLowerCase();
                    final secao = (data['secao'] ?? '').toString().toLowerCase();
                    final subsecao = (data['subsecao'] ?? '').toString().toLowerCase();
                    final busca = _filtro.toLowerCase();
                    return pergunta.contains(busca) ||
                        secao.contains(busca) ||
                        subsecao.contains(busca);
                  }).toList();
                }

                if (perguntas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filtro.isEmpty
                              ? 'Nenhuma pergunta cadastrada'
                              : 'Nenhuma pergunta encontrada',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _abrirModalPergunta(null),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Primeira Pergunta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Agrupar por seção e subseção
                final grupos = <String, Map<String, List<QueryDocumentSnapshot>>>{};
                for (final doc in perguntas) {
                  final data = doc.data() as Map<String, dynamic>;
                  final secao = data['secao'] ?? 'Sem seção';
                  final subsecao = data['subsecao'] ?? 'Sem subseção';

                  if (!grupos.containsKey(secao)) {
                    grupos[secao] = {};
                  }
                  if (!grupos[secao]!.containsKey(subsecao)) {
                    grupos[secao]![subsecao] = [];
                  }
                  grupos[secao]![subsecao]!.add(doc);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: grupos.keys.length,
                  itemBuilder: (context, index) {
                    final secao = grupos.keys.elementAt(index);
                    final subsecoes = grupos[secao]!;
                    return _buildSecaoCard(secao, subsecoes);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoCard(
    String secao,
    Map<String, List<QueryDocumentSnapshot>> subsecoes,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          secao,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        children: subsecoes.keys.map((subsecao) {
          final perguntas = subsecoes[subsecao]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subsecao != 'Sem subseção')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange.shade50,
                  width: double.infinity,
                  child: Text(
                    subsecao,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ...perguntas.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildPerguntaTile(doc.id, data);
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerguntaTile(String id, Map<String, dynamic> data) {
    final ativo = data['ativo'] ?? true;
    final ordem = data['ordem'] ?? 0;
    final pergunta = data['pergunta'] ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ativo ? Colors.orange.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            ordem.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ativo ? Colors.orange.shade900 : Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ),
      ),
      title: Text(
        pergunta,
        style: TextStyle(
          fontSize: 15,
          color: ativo ? Colors.black87 : Colors.grey.shade600,
          decoration: ativo ? null : TextDecoration.lineThrough,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          ativo ? Icons.visibility : Icons.visibility_off,
          color: ativo ? Colors.green : Colors.grey,
          size: 28,
        ),
        tooltip: ativo ? 'Desativar' : 'Ativar',
        onPressed: () => _toggleAtivo(id, ativo),
      ),
    );
  }

  Future<void> _abrirModalPergunta(Map<String, dynamic>? perguntaData) async {
    final tipoController = TextEditingController(text: _tipoSelecionado);
    final perguntaController = TextEditingController();
    bool ativo = true;

    // Opções de seção e subseção
    String? secaoSelecionada;
    String? subsecaoSelecionada;

    final secoesOperacionais = [
      'I - Fatores comportamentais',
      'II - Fatores técnicos',
    ];

    final subsecoesOperacionais = {
      'I - Fatores comportamentais': [
        'I.1 - Discrição',
        'I.2 - Urbanidade',
        'I.3 - Assiduidade',
        'I.4 - Pontualidade',
        'I.5 - Disciplina',
      ],
      'II - Fatores técnicos': [
        'II.1 - Conhecimento do trabalho',
        'II.2 - Qualidade do trabalho',
        'II.3 - Quantidade do trabalho',
        'II.4 - Capacidade de decisão',
        'II.5 - Iniciativa',
      ],
    };

    final secoesGerenciais = [
      'III - Fatores gerenciais da tarefa',
    ];

    final subsecoesGerenciais = {
      'III - Fatores gerenciais da tarefa': [
        'III.1 - Planejamento',
        'III.2 - Organização e controle',
        'III.3 - Liderança e relacionamento humano',
        'III.4 - Desenvolvimento de pessoal',
        'III.5 - Conhecimento técnico das funções',
      ],
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final secoes = tipoController.text == 'OPERACIONAL'
              ? secoesOperacionais
              : secoesGerenciais;
          final subsecoes = tipoController.text == 'OPERACIONAL'
              ? subsecoesOperacionais
              : subsecoesGerenciais;

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nova Pergunta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo
                    const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tipoController.text,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'OPERACIONAL',
                          child: Text('OPERACIONAL'),
                        ),
                        DropdownMenuItem(
                          value: 'GERENCIAL',
                          child: Text('GERENCIAL'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            tipoController.text = value;
                            secaoSelecionada = null;
                            subsecaoSelecionada = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Seção
                    const Text('Seção:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: secaoSelecionada,
                      decoration: InputDecoration(
                        hintText: 'Selecione a seção',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: secoes.map((secao) {
                        return DropdownMenuItem(
                          value: secao,
                          child: Text(secao),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          secaoSelecionada = value;
                          subsecaoSelecionada = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subseção
                    const Text('Subseção:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: subsecaoSelecionada,
                      decoration: InputDecoration(
                        hintText: 'Selecione a subseção',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: secaoSelecionada != null
                          ? subsecoes[secaoSelecionada]!.map((subsecao) {
                              return DropdownMenuItem(
                                value: subsecao,
                                child: Text(subsecao),
                              );
                            }).toList()
                          : [],
                      onChanged: secaoSelecionada != null
                          ? (value) {
                              setModalState(() {
                                subsecaoSelecionada = value;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Pergunta
                    const Text('Pergunta:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: perguntaController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Digite a pergunta completa...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ativo
                    CheckboxListTile(
                      title: const Text('Pergunta ativa'),
                      subtitle: const Text('Perguntas inativas não aparecem nos formulários'),
                      value: ativo,
                      onChanged: (value) {
                        setModalState(() {
                          ativo = value ?? true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validação
                  if (perguntaController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Digite a pergunta'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (secaoSelecionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione a seção'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (subsecaoSelecionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione a subseção'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Calcular ordem (pegar todas as perguntas da seção/subseção e encontrar a maior ordem)
                  final perguntasExistentes = await _firestore
                      .collection('questions')
                      .where('tipo', isEqualTo: tipoController.text)
                      .where('secao', isEqualTo: secaoSelecionada)
                      .where('subsecao', isEqualTo: subsecaoSelecionada)
                      .get();

                  int novaOrdem = 1;
                  if (perguntasExistentes.docs.isNotEmpty) {
                    // Encontrar a maior ordem
                    int maiorOrdem = 0;
                    for (final doc in perguntasExistentes.docs) {
                      final ordem = doc.data()['ordem'] ?? 0;
                      if (ordem > maiorOrdem) {
                        maiorOrdem = ordem;
                      }
                    }
                    novaOrdem = maiorOrdem + 1;
                  }

                  final dados = {
                    'tipo': tipoController.text,
                    'ordem': novaOrdem,
                    'secao': secaoSelecionada!,
                    'subsecao': subsecaoSelecionada!,
                    'pergunta': perguntaController.text.trim(),
                    'ativo': ativo,
                  };

                  await _adicionarPergunta(dados);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Adicionar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );

    tipoController.dispose();
    perguntaController.dispose();
  }

  Future<void> _adicionarPergunta(Map<String, dynamic> dados) async {
    try {
      await _firestore.collection('questions').add(dados);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pergunta adicionada com sucesso!',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar pergunta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAtivo(String id, bool ativoAtual) async {
    try {
      await _firestore.collection('questions').doc(id).update({
        'ativo': !ativoAtual,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ativoAtual ? 'Pergunta desativada' : 'Pergunta ativada',
              style: const TextStyle(fontSize: 16),
            ),
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
}
