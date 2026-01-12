import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'formulario_avaliacao_screen.dart';

class AutoavaliacaoScreen extends StatefulWidget {
  const AutoavaliacaoScreen({super.key});

  @override
  State<AutoavaliacaoScreen> createState() => _AutoavaliacaoScreenState();
}

class _AutoavaliacaoScreenState extends State<AutoavaliacaoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
              stream: _firestore
                  .collection('funcionarios')
                  .snapshots(),
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

                // Filtro de busca
                if (_searchQuery.isNotEmpty) {
                  employees = employees.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nome = (data['nome'] ?? '').toLowerCase();
                    final chapa = (data['chapa'] ?? '').toLowerCase();
                    return nome.contains(_searchQuery) ||
                        chapa.contains(_searchQuery);
                  }).toList();
                }

                if (employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off,
                            size: 80, color: Colors.grey.shade400),
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final doc = employees[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final chapa = doc.id;

                    return _buildEmployeeCard(chapa, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(String chapa, Map<String, dynamic> data) {
    final nome = data['nome'] ?? '';
    final funcao = data['funcao'] ?? '';
    final nivel = data['nivel'] ?? '';
    final isManager = data['isManager'] ?? false;

    return FutureBuilder<bool>(
      future: _hasAutoavaliacao(chapa),
      builder: (context, snapshot) {
        final jaAvaliou = snapshot.data ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          child: InkWell(
            onTap: () => _showPasswordDialog(chapa, data),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        isManager ? Colors.blue.shade700 : Colors.grey.shade600,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$funcao - Nível $nivel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'Chapa: $chapa',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (jaAvaliou)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Concluído',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.blue,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _hasAutoavaliacao(String chapa) async {
    try {
      final configDoc = await _firestore.collection('config').doc('general').get();
      final cycle = configDoc.data()?['currentCycle'] ?? '2024/2025';

      final year = cycle.split('/')[0];
      final docId = '${year}_${chapa}_AUTO';

      final doc = await _firestore.collection('evaluations').doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
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
      final configDoc = await _firestore.collection('config').doc('general').get();
      final adminPassword = configDoc.data()?['adminPassword'] ?? '1234';
      return password == adminPassword;
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
        ),
      ),
    ).then((_) {
      // Atualiza a lista quando voltar
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
