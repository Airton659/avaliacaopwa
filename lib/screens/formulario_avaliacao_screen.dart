import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormularioAvaliacaoScreen extends StatefulWidget {
  final String chapa;
  final Map<String, dynamic> employeeData;
  final bool isAutoavaliacao;
  final bool isGerencial;

  const FormularioAvaliacaoScreen({
    super.key,
    required this.chapa,
    required this.employeeData,
    required this.isAutoavaliacao,
    required this.isGerencial,
  });

  @override
  State<FormularioAvaliacaoScreen> createState() =>
      _FormularioAvaliacaoScreenState();
}

class _FormularioAvaliacaoScreenState
    extends State<FormularioAvaliacaoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _obsController = TextEditingController();
  final Map<String, int> _respostas = {};
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _questoes = [];

  @override
  void initState() {
    super.initState();
    _carregarPerguntas();
  }

  Future<void> _carregarPerguntas() async {
    try {
      // Buscar perguntas do Firestore baseado no tipo
      final tipo = widget.isGerencial ? 'GERENCIAL' : 'OPERACIONAL';

      final snapshot = await _firestore
          .collection('questions')
          .where('tipo', isEqualTo: tipo)
          .where('ativo', isEqualTo: true)
          .orderBy('ordem')
          .get();

      if (snapshot.docs.isEmpty) {
        // Se não houver perguntas no Firestore, usar perguntas padrão
        setState(() {
          _questoes = widget.isGerencial
              ? _questoesPadraoGerenciais
              : _questoesPadraoOperacionais;
          _isLoading = false;
        });
        return;
      }

      // Agrupar perguntas por seção e subseção
      final Map<String, Map<String, List<String>>> agrupadas = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final secao = data['secao'] ?? '';
        final subsecao = data['subsecao'] ?? '';
        final pergunta = data['pergunta'] ?? '';

        if (!agrupadas.containsKey(secao)) {
          agrupadas[secao] = {};
        }
        if (!agrupadas[secao]!.containsKey(subsecao)) {
          agrupadas[secao]![subsecao] = [];
        }
        agrupadas[secao]![subsecao]!.add(pergunta);
      }

      // Converter para formato esperado
      final List<Map<String, dynamic>> questoesFormatadas = [];
      agrupadas.forEach((secao, subsecoes) {
        subsecoes.forEach((subsecao, perguntas) {
          questoesFormatadas.add({
            'secao': secao,
            'subsecao': subsecao,
            'perguntas': perguntas,
          });
        });
      });

      setState(() {
        _questoes = questoesFormatadas;
        _isLoading = false;
      });
    } catch (e) {
      // Em caso de erro, usar perguntas padrão
      setState(() {
        _questoes = widget.isGerencial
            ? _questoesPadraoGerenciais
            : _questoesPadraoOperacionais;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmarLimpeza() async {
    if (_respostas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não há respostas para limpar.',
            style: TextStyle(fontSize: 16),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Limpar Respostas?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Você tem certeza que deseja limpar todas as ${_respostas.length} respostas?\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar Tudo', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _respostas.clear();
        _obsController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Todas as respostas foram limpas.',
              style: TextStyle(fontSize: 16),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Perguntas padrão (fallback) - operacional
  final List<Map<String, dynamic>> _questoesPadraoOperacionais = [
    {
      'secao': 'I - Fatores comportamentais',
      'subsecao': 'I.1 - Discrição',
      'perguntas': [
        'comportamento discreto em suas relações de trabalho',
        'discrição em relação a fatos ocorridos no setor de trabalho',
        'atitude respeitosa em relação à chefia, a colegas e ao público',
        'guarda responsável de documentos e informações sigilosos',
      ],
    },
    {
      'secao': 'I - Fatores comportamentais',
      'subsecao': 'I.2 - Assiduidade',
      'perguntas': [
        'assiduidade ao trabalho (frequência mínima de 95%)',
        'pontualidade no cumprimento de horários',
        'permanência regular no local de trabalho',
        'atenção no exercício das funções',
      ],
    },
    {
      'secao': 'I - Fatores comportamentais',
      'subsecao': 'I.3 - Disciplina',
      'perguntas': [
        'presteza no cumprimento de ordens',
        'administração do tempo e cumprimento de prazos',
        'uso adequado de equipamentos e instalações',
        'adaptação a trabalhos em equipe',
        'comportamento equilibrado no ambiente de trabalho',
      ],
    },
    {
      'secao': 'II - Fatores operacionais / Produtividade',
      'subsecao': '',
      'perguntas': [
        'qualidade e exatidão na execução de tarefas',
        'aptidão para as funções do Emprego Público',
        'iniciativa e comportamento produtivo',
        'aproveitamento/racionalização de recursos e processos de trabalho',
        'volume de produção no trabalho sob sua responsabilidade',
        'aproveitamento de oportunidades de capacitação',
        'capacidade para auxiliar outros empregados públicos',
      ],
    },
  ];

  // Perguntas padrão (fallback) - gerencial
  final List<Map<String, dynamic>> _questoesPadraoGerenciais = [
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.1 - Decisão',
      'perguntas': [
        'discernimento na análise de situações de trabalho',
        'prontidão e acerto na tomada de decisões',
        'equilíbrio frente a situações inesperadas',
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.2 - Liderança',
      'perguntas': [
        'segurança e independência nos relacionamentos de trabalho',
        'diálogo com superiores e subordinados, e delegação de responsabilidades',
        'colaboração e imparcialidade nas relações com superiores e/ou subordinados',
        'exercício de influência positiva sobre o grupo',
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.3 - Gestão',
      'perguntas': [
        'acompanhamento da execução de tarefas pelos empregados públicos sob sua chefia',
        'incentivo à produção e fornecimento de informação e orientação a seus subordinados',
        'acionamento de mecanismos da administração para capacitação profissional própria e de seus subordinados',
        'acionamento de procedimentos de segurança do trabalho',
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.4 - Planejamento do trabalho',
      'perguntas': [
        'organização de roteiros racionais e planejamento de tarefas de acordo com o fluxo das demandas',
        'análise de itinerários e procedimentos, por mensuração de espaço, distâncias e tempo de execução de tarefas',
        'estabelecimento de ritmo constante para realização de tarefas e consecução de resultados dentro das metas pré-estabelecidas',
        'exigência de ordem e higiene nos locais de trabalho',
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.5 - Conhecimento técnico das funções',
      'perguntas': [
        'domínio de conhecimentos na sua área de atuação',
        'conhecimento e visão global da estrutura e do funcionamento da organização',
        'habilidade no trato do público em geral',
        'interpretação e cumprimento de normas e regulamentos',
        'observância de prioridades e do interesse público em relação ao trabalho sob sua responsabilidade',
      ],
    },
  ];

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _questoesAtuais => _questoes;

  int get _totalPerguntas {
    int total = 0;
    for (var secao in _questoesAtuais) {
      total += (secao['perguntas'] as List).length;
    }
    return total;
  }

  bool get _todasRespondidas => _respostas.length == _totalPerguntas;

  double get _mediaRespostas {
    if (_respostas.isEmpty) return 0;
    int soma = _respostas.values.fold(0, (prev, curr) => prev + curr);
    return soma / _respostas.length;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirmExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair da Avaliação?'),
            content: const Text(
              'Você tem certeza que deseja sair? As respostas não salvas serão perdidas.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );

        if (confirmExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isAutoavaliacao ? 'Autoavaliação' : 'Avaliação do Gestor',
            style: const TextStyle(fontSize: 20),
          ),
          backgroundColor: widget.isAutoavaliacao ? Colors.blue : Colors.purple,
          actions: [
            IconButton(
              icon: const Icon(Icons.clear_all, size: 28),
              tooltip: 'Limpar todas as respostas',
              onPressed: () {
                _confirmarLimpeza();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Carregando perguntas...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho com informações do funcionário
                    Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isAutoavaliacao
                      ? [Colors.blue.shade700, Colors.blue.shade500]
                      : [Colors.purple.shade700, Colors.purple.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome e tipo de avaliação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.employeeData['nome'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          widget.isGerencial ? 'GERENCIAL' : 'OPERACIONAL',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid com informações do funcionário
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Chapa',
                                widget.chapa,
                                Icons.badge,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Admissão',
                                widget.employeeData['data_admissao'] ?? 'N/A',
                                Icons.calendar_today,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Função',
                                widget.employeeData['funcao'] ?? 'N/A',
                                Icons.work,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Escolaridade',
                                widget.employeeData['escolaridade'] ?? 'N/A',
                                Icons.school,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Nível',
                                widget.employeeData['nomenivel'] ??
                                  'Nível ${widget.employeeData['nivel'] ?? 'N/A'}',
                                Icons.trending_up,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Faixa',
                                widget.employeeData['nomefaixa'] ??
                                  'Faixa ${widget.employeeData['grau'] ?? 'N/A'}',
                                Icons.grade,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Barra de progresso
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progresso da Avaliação',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_respostas.length}/$_totalPerguntas',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _totalPerguntas > 0
                              ? _respostas.length / _totalPerguntas
                              : 0,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Instruções
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instruções
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSTRUÇÕES:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Marque a opção que melhor responda ao fator avaliado:',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1 - RUIM  |  2 - REGULAR  |  3 - BOM  |  4 - MUITO BOM  |  5 - ÓTIMO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Renderiza todas as seções
                    ..._buildQuestoes(),

                    const SizedBox(height: 24),

                    // Campo de observações
                    const Text(
                      'Observações (opcional):',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _obsController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Digite suas observações aqui...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 32),

                    // Botão de enviar
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _todasRespondidas && !_isSubmitting
                            ? _salvarAvaliacao
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.isAutoavaliacao ? Colors.blue : Colors.purple,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _todasRespondidas
                                    ? 'FINALIZAR AVALIAÇÃO'
                                    : 'RESPONDA TODAS AS PERGUNTAS PARA CONTINUAR',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  List<Widget> _buildQuestoes() {
    List<Widget> widgets = [];
    int perguntaIndex = 0;

    for (var secao in _questoesAtuais) {
      // Título da seção
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: (widget.isAutoavaliacao ? Colors.blue : Colors.purple)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            secao['secao'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));

      // Subseção (se existir)
      if (secao['subsecao'] != null && secao['subsecao'] != '') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Text(
              secao['subsecao'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      // Perguntas
      for (var pergunta in secao['perguntas']) {
        final key = 'q$perguntaIndex';
        widgets.add(_buildPergunta(key, pergunta));
        widgets.add(const SizedBox(height: 20));
        perguntaIndex++;
      }

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildPergunta(String key, String pergunta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _respostas.containsKey(key)
              ? Colors.green
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (_respostas.containsKey(key))
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_respostas.containsKey(key))
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              if (_respostas.containsKey(key)) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pergunta,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 1; i <= 5; i++) _buildOpcao(key, i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpcao(String key, int valor) {
    final isSelected = _respostas[key] == valor;
    final cores = {
      1: Colors.red,
      2: Colors.orange,
      3: Colors.yellow.shade700,
      4: Colors.lightGreen,
      5: Colors.green,
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          _respostas[key] = valor;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? cores[valor] : Colors.white,
          border: Border.all(
            color: cores[valor]!,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cores[valor]!.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            valor.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : cores[valor],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _salvarAvaliacao() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Obter ciclo atual
      final configDoc = await _firestore.collection('config').doc('general').get();
      final ciclo = configDoc.data()?['currentCycle'] ?? '2024/2025';
      final ano = ciclo.split('/')[0];

      // Definir tipo de avaliação
      String tipo;
      if (widget.isAutoavaliacao) {
        tipo = widget.isGerencial ? 'AUTO_GERENCIAL' : 'AUTO_OPERACIONAL';
      } else {
        tipo = widget.isGerencial ? 'GESTOR_GERENCIAL' : 'GESTOR_OPERACIONAL';
      }

      // ID do documento
      final docId = widget.isAutoavaliacao
          ? '${ano}_${widget.chapa}_AUTO'
          : '${ano}_${widget.chapa}_GESTOR';

      // Criar snapshot do funcionário
      final employeeSnapshot = {
        'chapa': widget.chapa,
        'nome': widget.employeeData['nome'],
        'funcao': widget.employeeData['funcao'],
        'nivel': widget.employeeData['nivel'],
        'grau': widget.employeeData['grau'],
        'isManager': widget.employeeData['isManager'] ?? false,
      };

      // Salvar avaliação
      await _firestore.collection('evaluations').doc(docId).set({
        'chapa': widget.chapa,
        'ciclo': ciclo,
        'ano': ano,
        'tipo': tipo,
        'isAutoavaliacao': widget.isAutoavaliacao,
        'isGerencial': widget.isGerencial,
        'respostas': _respostas,
        'observacoes': _obsController.text,
        'media': _mediaRespostas,
        'totalPerguntas': _totalPerguntas,
        'employeeSnapshot': employeeSnapshot,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Avaliação salva com sucesso!',
              style: TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Aguardar um pouco e voltar
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar avaliação: $e',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
