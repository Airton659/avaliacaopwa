import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'formulario_avaliacao_screen.dart';

class AvaliacaoGestorScreen extends StatefulWidget {
  const AvaliacaoGestorScreen({super.key});

  @override
  State<AvaliacaoGestorScreen> createState() => _AvaliacaoGestorScreenState();
}

class _AvaliacaoGestorScreenState extends State<AvaliacaoGestorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _filtro = '';

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
          'Avaliação do Gestor',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple.shade700,
      ),
      body: Column(
        children: [
          // Campo de busca
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _filtro = value;
                });
              },
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Buscar gestor...',
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
          ),
          // Lista de gestores
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('funcionarios')
                  .where('isManager', isEqualTo: true)
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

                var gestores = snapshot.data!.docs;

                // Filtrar apenas gestores ativos
                gestores = gestores.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['ativo'] == true;
                }).toList();

                // Filtrar gestores por busca
                if (_filtro.isNotEmpty) {
                  gestores = gestores.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nome = (data['nome'] ?? '').toString().toLowerCase();
                    final funcao = (data['funcao'] ?? '').toString().toLowerCase();
                    final busca = _filtro.toLowerCase();
                    return nome.contains(busca) || funcao.contains(busca);
                  }).toList();
                }

                if (gestores.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum gestor encontrado',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gestores.length,
                  itemBuilder: (context, index) {
                    final doc = gestores[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildGestorCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestorCard(String chapa, Map<String, dynamic> data) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('funcionarios')
          .where('managerId', isEqualTo: chapa)
          .get(),
      builder: (context, snapshot) {
        final subordinadosAtivos = snapshot.hasData
            ? snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['ativo'] == true;
              }).length
            : 0;
        final subordinadosCount = subordinadosAtivos;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _abrirModalSenha(chapa, data),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.purple.shade700,
                    child: const Icon(
                      Icons.supervisor_account,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['nome'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['funcao'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$subordinadosCount subordinado(s)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirModalSenha(String gestorChapa, Map<String, dynamic> gestorData) async {
    final senhaController = TextEditingController();
    bool senhaIncorreta = false;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.lock, color: Colors.purple.shade700, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Senha do Administrador',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para avaliar a equipe de ${gestorData['nome']}, digite a senha do administrador.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  autofocus: true,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    labelStyle: const TextStyle(fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: senhaIncorreta ? 'Senha incorreta' : null,
                  ),
                  onSubmitted: (value) async {
                    final senhaCorreta = await _verificarSenha(value);
                    if (senhaCorreta) {
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } else {
                      setModalState(() {
                        senhaIncorreta = true;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final senhaCorreta = await _verificarSenha(senhaController.text);
                  if (senhaCorreta) {
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  } else {
                    setModalState(() {
                      senhaIncorreta = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );

    senhaController.dispose();

    if (resultado == true && mounted) {
      _iniciarLoopAvaliacao(gestorChapa, gestorData);
    }
  }

  Future<bool> _verificarSenha(String senha) async {
    // Buscar a senha do admin no Firestore
    try {
      final doc = await _firestore.collection('config').doc('general').get();
      final senhaAdmin = doc.data()?['adminPassword'] ?? '123456';
      return senha == senhaAdmin;
    } catch (e) {
      // Se não encontrar a senha no Firestore, usa senha padrão
      return senha == '123456';
    }
  }

  Future<void> _iniciarLoopAvaliacao(String gestorChapa, Map<String, dynamic> gestorData) async {
    // Buscar subordinados do gestor
    final subordinadosSnapshot = await _firestore
        .collection('funcionarios')
        .where('managerId', isEqualTo: gestorChapa)
        .get();

    // Filtrar apenas subordinados ativos
    final subordinados = subordinadosSnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['ativo'] == true;
    }).toList();

    if (subordinados.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${gestorData['nome']} não possui subordinados para avaliar.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }
      return;
    }

    // Loop de avaliação
    int avaliadasComSucesso = 0;
    for (int i = 0; i < subordinados.length; i++) {
      final subordinado = subordinados[i];
      final subordinadoData = subordinado.data();
      final isGerencial = subordinadoData['isManager'] == true;

      if (!mounted) return;

      // Navegar para o formulário de avaliação
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormularioAvaliacaoScreen(
            chapa: subordinado.id,
            employeeData: subordinadoData,
            isAutoavaliacao: false,
            isGerencial: isGerencial,
            avaliacaoAtual: i + 1,
            totalAvaliacoes: subordinados.length,
          ),
        ),
      );

      // Se o usuário cancelou (voltou sem salvar), interrompe o loop
      if (resultado != true) {
        return; // Volta para a lista de gestores
      }

      avaliadasComSucesso++;
    }

    // Após avaliar todos, mostrar mensagem de conclusão
    if (mounted && avaliadasComSucesso == subordinados.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Avaliações Concluídas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Todas as avaliações da equipe de ${gestorData['nome']} foram concluídas com sucesso!',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }
}
