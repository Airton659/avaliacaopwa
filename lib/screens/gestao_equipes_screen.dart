import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/situacao_helper.dart';
import '../widgets/multi_situacao_filter.dart';
import '../widgets/multi_tipo_filter.dart';
import '../widgets/expandable_filter_section.dart';
import 'dashboard_gestor_screen.dart';
import '../utils/password_helper.dart';

class GestaoEquipesScreen extends StatefulWidget {
  const GestaoEquipesScreen({super.key});

  @override
  State<GestaoEquipesScreen> createState() => _GestaoEquipesScreenState();
}

class _GestaoEquipesScreenState extends State<GestaoEquipesScreen> {
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestão de Equipes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('funcionarios')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs;

          // Filtra apenas funcionários ativos
          var employeesAtivos = employees.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['ativo'] == true;
          }).toList();

          // Coletar situações e tipos únicos dos funcionários ativos
          final situacoesDisponiveis = <String>{};
          final tiposDisponiveis = <String>{};

          for (var doc in employeesAtivos) {
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
            employeesAtivos = employeesAtivos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nome = (data['nome']?.toString() ?? '').toLowerCase();
              final funcao = (data['funcao']?.toString() ?? '').toLowerCase();
              final chapa = doc.id.toLowerCase();
              return nome.contains(_searchQuery) || funcao.contains(_searchQuery) || chapa.contains(_searchQuery);
            }).toList();
          }

          // Filtro por situação (multi-seleção)
          if (_filtrosSituacao.isNotEmpty) {
            employeesAtivos = employeesAtivos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final situacao = data['situacao']?.toString() ?? '';
              return _filtrosSituacao.contains(situacao.toUpperCase());
            }).toList();
          }

          // Filtro por tipo (multi-seleção)
          if (_filtrosTipo.isNotEmpty) {
            employeesAtivos = employeesAtivos.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final tipo = data['codtipo']?.toString() ?? '';
              return _filtrosTipo.contains(tipo.toUpperCase());
            }).toList();
          }

          // Separa funcionários sem gestor e gestores
          final semGestor = employeesAtivos.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['managerId'] == null;
          }).toList();

          final gestores = employeesAtivos.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isManager'] == true;
          }).toList();

          // Layout responsivo: coluna única em mobile, duas colunas em tablet/desktop
          if (isMobile) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Barra de busca e filtro
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue.shade50,
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar funcionário',
                            labelStyle: const TextStyle(fontSize: 16),
                            prefixIcon: const Icon(Icons.search),
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
                          style: const TextStyle(fontSize: 16),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                        if (situacoesDisponiveis.isNotEmpty || tiposDisponiveis.isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                  TabBar(
                    labelColor: Colors.blue.shade700,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue.shade700,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.person_outline),
                        text: 'Sem Gestor',
                      ),
                      Tab(
                        icon: Icon(Icons.supervisor_account),
                        text: 'Gestores',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Funcionários sem gestor
                        Container(
                          color: Colors.grey.shade100,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: semGestor.length,
                            itemBuilder: (context, index) {
                              final doc = semGestor[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildFuncionarioCard(doc.id, data, enableDrag: false);
                            },
                          ),
                        ),
                        // Tab 2: Gestores e equipes
                        Container(
                          color: Colors.white,
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
                ],
              ),
            );
          }

          // Layout para tablet/desktop: duas colunas lado a lado
          return Column(
            children: [
              // Barra de busca e filtro no topo
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar funcionário',
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.search),
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
                        style: const TextStyle(fontSize: 16),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    if (situacoesDisponiveis.isNotEmpty || tiposDisponiveis.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(
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
                    ],
                  ],
                ),
              ),
              // Duas colunas
              Expanded(
                child: Row(
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
                                  return _buildFuncionarioCard(doc.id, data, enableDrag: true);
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFuncionarioCard(String chapa, Map<String, dynamic> data, {required bool enableDrag}) {
    final content = _buildCardContent(data, false);

    if (!enableDrag) {
      return content;
    }

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
                      data['nome']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data['funcao']?.toString() ?? '',
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
        child: content,
      ),
      child: content,
    );
  }

  Widget _buildCardContent(Map<String, dynamic> data, bool isGestor) {
    final situacao = SituacaoHelper.getDescricaoCompleta(data['situacao']?.toString());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isGestor ? Colors.blue : Colors.grey,
          child: Icon(
            isGestor ? Icons.supervisor_account : Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          data['nome']?.toString() ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['funcao']?.toString() ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Mat: ${data['chapa'] ?? ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              situacao,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: isGestor
            ? null
            : IconButton(
                icon: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
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
              InkWell(
                onTap: () => _abrirModalEdicaoEquipe(
                  gestorChapa,
                  gestorData,
                  allEmployees,
                ),
                child: Container(
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
                      IconButton(
                        icon: const Icon(Icons.vpn_key, color: Colors.white),
                        tooltip: 'Definir Senha de Acesso',
                        onPressed: () => _definirSenhaGestor(gestorChapa, gestorData),
                      ),
                      const Icon(Icons.edit, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      if (subordinados.isEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          tooltip: 'Rebaixar Gestor',
                          onPressed: () => _rebaixarGestor(gestorChapa),
                        ),
                    ],
                  ),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: const Icon(Icons.person_outline, size: 28),
                            title: Text(
                              data['nome']?.toString() ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              data['funcao']?.toString() ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red, size: 28),
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

  Future<void> _abrirModalEdicaoEquipe(
    String gestorChapa,
    Map<String, dynamic> gestorData,
    List<QueryDocumentSnapshot> allEmployees,
  ) async {
    // IDs dos subordinados atuais deste gestor
    final subordinadosAtuais = allEmployees
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['managerId'] == gestorChapa;
        })
        .map((doc) => doc.id)
        .toSet();

    // Apenas funcionários sem gestor OU que já são subordinados deste gestor
    final funcionarios = allEmployees.where((doc) {
      if (doc.id == gestorChapa) return false; // Não pode atribuir a si mesmo
      final data = doc.data() as Map<String, dynamic>;
      final managerId = data['managerId'];
      // Mostra se: não tem gestor OU é subordinado deste gestor
      return managerId == null || managerId == gestorChapa;
    }).toList();

    // Set para controlar seleções
    final selecionados = Set<String>.from(subordinadosAtuais);

    String filtro = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {

          final funcionariosFiltrados = funcionarios.where((doc) {
            if (filtro.isEmpty) return true;
            final data = doc.data() as Map<String, dynamic>;
            final nome = (data['nome']?.toString() ?? '').toString().toLowerCase();
            final funcao = (data['funcao']?.toString() ?? '').toString().toLowerCase();
            final busca = filtro.toLowerCase();
            final chapa = doc.id.toLowerCase();
            return nome.contains(busca) || funcao.contains(busca) || chapa.contains(busca);
          }).toList();

          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: Column(
                children: [
                  // Cabeçalho
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  const Text(
                                    'Editar Equipe',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    gestorData['nome'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Campo de busca
                        TextField(
                          onChanged: (value) {
                            setModalState(() {
                              filtro = value;
                            });
                          },
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Buscar funcionário...',
                            hintStyle: const TextStyle(fontSize: 16),
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de funcionários
                  Expanded(
                    child: funcionariosFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum funcionário encontrado',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: funcionariosFiltrados.length,
                            itemBuilder: (context, index) {
                              final doc = funcionariosFiltrados[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final chapa = doc.id;
                              final isSelected = selecionados.contains(chapa);

                              return CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                secondary: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  data['nome']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${data['funcao']?.toString() ?? ''} - Mat: $chapa',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selecionados.add(chapa);
                                    } else {
                                      selecionados.remove(chapa);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  // Rodapé com botões
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selecionados.length} selecionado(s)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await _salvarEquipe(
                                  gestorChapa,
                                  subordinadosAtuais,
                                  selecionados,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Salvar',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _definirSenhaGestor(String chapa, Map<String, dynamic> data) async {
    final passwordController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Definir Senha - ${data['nome']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta senha será usada pelo gestor para acessar o painel de avaliações.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
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
            onPressed: () async {
              if (passwordController.text.isNotEmpty) {
                 await _firestore.collection('funcionarios').doc(chapa).update({
                   'password': PasswordHelper.hashPassword(passwordController.text),
                   'isFirstAccess': true, // Força troca de senha ou fluxo inicial se quisermos
                 });
                 if (mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Senha definida com sucesso!')),
                   );
                 }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvarEquipe(
    String gestorChapa,
    Set<String> subordinadosAntigos,
    Set<String> subordinadosNovos,
  ) async {
    try {
      // Remover os que foram desmarcados
      final removidos = subordinadosAntigos.difference(subordinadosNovos);
      for (final chapa in removidos) {
        await _firestore.collection('funcionarios').doc(chapa).update({
          'managerId': null,
        });
      }

      // Adicionar os que foram marcados
      final adicionados = subordinadosNovos.difference(subordinadosAntigos);
      for (final chapa in adicionados) {
        await _firestore.collection('funcionarios').doc(chapa).update({
          'managerId': gestorChapa,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Equipe atualizada com sucesso',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _promoverGestor(String chapa) async {
    try {
      await _firestore.collection('funcionarios').doc(chapa).update({
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
      await _firestore.collection('funcionarios').doc(chapa).update({
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
      await _firestore.collection('funcionarios').doc(chapaSubordinado).update({
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
      await _firestore.collection('funcionarios').doc(chapa).update({
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
