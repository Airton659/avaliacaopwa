import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'signature_screen.dart';
import 'package:intl/intl.dart';
import '../utils/situacao_helper.dart';

class FormularioAvaliacaoScreen extends StatefulWidget {
  final String chapa;
  final Map<String, dynamic> employeeData;
  final bool isAutoavaliacao;
  final bool isGerencial;
  final int? avaliacaoAtual;
  final int? totalAvaliacoes;

  final String authorMatricula;
  final bool requestSignature;

  const FormularioAvaliacaoScreen({
    super.key,
    required this.chapa,
    required this.employeeData,
    required this.isAutoavaliacao,
    required this.isGerencial,
    required this.authorMatricula,
    this.avaliacaoAtual,
    this.totalAvaliacoes,
    this.requestSignature = true,
    this.allowSaveWithoutSignature = false,
  });

  final bool allowSaveWithoutSignature;

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

  bool _isReadOnly = false;
  String? _signatureUrl;
  String? _photoUrl;
  Map<String, dynamic>? _signatureMetadata;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    await _carregarPerguntas();
    await _verificarAvaliacaoExistente();
  }

  Future<void> _verificarAvaliacaoExistente() async {
    try {
      final configDoc = await _firestore.collection('config').doc('general').get();
      final ano = configDoc.data()?['currentCycle'] ?? '2026';

      final docId = widget.isAutoavaliacao
          ? '${ano}_${widget.chapa}_AUTO'
          : '${ano}_${widget.chapa}_GESTOR';

      final doc = await _firestore.collection('evaluations').doc(docId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final status = data['status'] as String? ?? 'pendente';

        // Travamento apenas se já foi assinada (concluida)
        // O usuário pediu: "depois q foi preenchida e assinada, não pode ser alterada mais"
        // Status 'aguardando_assinatura' ainda pode permitir edição se o gestor quiser corrigir antes de assinar?
        // Geralmente sim, mas se for "preenchida" (salva), talvez ele queira travar também.
        // Pelo pedido "preenchida E assinada", vou travar apenas em 'concluida'.
        // Mas se estiver 'aguardando_assinatura', o funcionário já preencheu?
        // Se for GESTOR avaliando, ele salva -> aguardando_assinatura.
        // Se ele entrar de novo, deve poder editar? Normalmente sim, até assinar.
        // Vou travar APENAS se status == 'concluida' (que implica assinada).

        if (status == 'concluida') {
           setState(() {
             _isReadOnly = true;
             // Carregar respostas para visualização
             if (data['respostas'] != null) {
               final rawRespostas = Map<String, int>.from(data['respostas']);
               
               // Migração de chaves antigas (q0, q1) para IDs (FKs)
               // Criar lista plana de IDs na ordem correta para mapear índices
               final List<String> orderedIds = [];
               for (var secao in _questoes) {
                 for (var p in secao['perguntas']) {
                   orderedIds.add(p['id']);
                 }
               }

               rawRespostas.forEach((key, value) {
                 if (key.startsWith('q') && int.tryParse(key.substring(1)) != null) {
                   // É chave legada (q0, q1...)
                   final index = int.tryParse(key.substring(1))!;
                   if (index < orderedIds.length) {
                     _respostas[orderedIds[index]] = value;
                   }
                 } else {
                   // É chave nova (ID)
                   _respostas[key] = value;
                 }
               });
             }
               if (data['observacoes'] != null) {
                 _obsController.text = data['observacoes'];
               }
               _signatureUrl = data['signatureUrl'];
               _photoUrl = data['managerPhotoUrl'] ?? data['photoUrl']; // Tenta managerPhotoUrl primeiro, fallback para photoUrl
               if (data['managerSignatureMetadata'] != null) {
                 _signatureMetadata = Map<String, dynamic>.from(data['managerSignatureMetadata']);
               }
           });
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar avaliação existente: $e');
    }
  }

  Future<void> _carregarPerguntas() async {
    try {
      // Buscar perguntas do Firestore baseado no tipo
      final tipo = widget.isGerencial ? 'GERENCIAL' : 'OPERACIONAL';

      final snapshot = await _firestore
          .collection('questions')
          .where('tipo', isEqualTo: tipo)
          .where('ativo', isEqualTo: true)
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

      // Ordenar perguntas por ordem
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final ordemA = a.data()['ordem'] ?? 0;
        final ordemB = b.data()['ordem'] ?? 0;
        return ordemA.compareTo(ordemB);
      });

      // Agrupar perguntas por seção e subseção
      final Map<String, Map<String, List<Map<String, dynamic>>>> agrupadas = {};

      for (var doc in docs) {
        final data = doc.data();
        final secao = data['secao'] ?? '';
        final subsecao = data['subsecao'] ?? '';
        final perguntaTexto = data['pergunta'] ?? '';
        final perguntaId = doc.id; // USAR ID DO DOCUMENTO

        if (!agrupadas.containsKey(secao)) {
          agrupadas[secao] = {};
        }
        if (!agrupadas[secao]!.containsKey(subsecao)) {
          agrupadas[secao]![subsecao] = [];
        }
        agrupadas[secao]![subsecao]!.add({
          'id': perguntaId,
          'texto': perguntaTexto,
        });
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
        {'id': 'op_1_1', 'texto': 'comportamento discreto em suas relações de trabalho'},
        {'id': 'op_1_2', 'texto': 'discrição em relação a fatos ocorridos no setor de trabalho'},
        {'id': 'op_1_3', 'texto': 'atitude respeitosa em relação à chefia, a colegas e ao público'},
        {'id': 'op_1_4', 'texto': 'guarda responsável de documentos e informações sigilosos'},
      ],
    },
    {
      'secao': 'I - Fatores comportamentais',
      'subsecao': 'I.2 - Assiduidade',
      'perguntas': [
        {'id': 'op_2_1', 'texto': 'assiduidade ao trabalho (frequência mínima de 95%)'},
        {'id': 'op_2_2', 'texto': 'pontualidade no cumprimento de horários'},
        {'id': 'op_2_3', 'texto': 'permanência regular no local de trabalho'},
        {'id': 'op_2_4', 'texto': 'atenção no exercício das funções'},
      ],
    },
    {
      'secao': 'I - Fatores comportamentais',
      'subsecao': 'I.3 - Disciplina',
      'perguntas': [
        {'id': 'op_3_1', 'texto': 'presteza no cumprimento de ordens'},
        {'id': 'op_3_2', 'texto': 'administração do tempo e cumprimento de prazos'},
        {'id': 'op_3_3', 'texto': 'uso adequado de equipamentos e instalações'},
        {'id': 'op_3_4', 'texto': 'adaptação a trabalhos em equipe'},
        {'id': 'op_3_5', 'texto': 'comportamento equilibrado no ambiente de trabalho'},
      ],
    },
    {
      'secao': 'II - Fatores operacionais / Produtividade',
      'subsecao': '',
      'perguntas': [
        {'id': 'op_4_1', 'texto': 'qualidade e exatidão na execução de tarefas'},
        {'id': 'op_4_2', 'texto': 'aptidão para as funções do Emprego Público'},
        {'id': 'op_4_3', 'texto': 'iniciativa e comportamento produtivo'},
        {'id': 'op_4_4', 'texto': 'aproveitamento/racionalização de recursos e processos de trabalho'},
        {'id': 'op_4_5', 'texto': 'volume de produção no trabalho sob sua responsabilidade'},
        {'id': 'op_4_6', 'texto': 'aproveitamento de oportunidades de capacitação'},
        {'id': 'op_4_7', 'texto': 'capacidade para auxiliar outros empregados públicos'},
      ],
    },
  ];

  // Perguntas padrão (fallback) - gerencial
  final List<Map<String, dynamic>> _questoesPadraoGerenciais = [
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.1 - Decisão',
      'perguntas': [
        {'id': 'ger_1_1', 'texto': 'discernimento na análise de situações de trabalho'},
        {'id': 'ger_1_2', 'texto': 'prontidão e acerto na tomada de decisões'},
        {'id': 'ger_1_3', 'texto': 'equilíbrio frente a situações inesperadas'},
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.2 - Liderança',
      'perguntas': [
        {'id': 'ger_2_1', 'texto': 'segurança e independência nos relacionamentos de trabalho'},
        {'id': 'ger_2_2', 'texto': 'diálogo com superiores e subordinados, e delegação de responsabilidades'},
        {'id': 'ger_2_3', 'texto': 'colaboração e imparcialidade nas relações com superiores e/ou subordinados'},
        {'id': 'ger_2_4', 'texto': 'exercício de influência positiva sobre o grupo'},
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.3 - Gestão',
      'perguntas': [
        {'id': 'ger_3_1', 'texto': 'acompanhamento da execução de tarefas pelos empregados públicos sob sua chefia'},
        {'id': 'ger_3_2', 'texto': 'incentivo à produção e fornecimento de informação e orientação a seus subordinados'},
        {'id': 'ger_3_3', 'texto': 'acionamento de mecanismos da administração para capacitação profissional própria e de seus subordinados'},
        {'id': 'ger_3_4', 'texto': 'acionamento de procedimentos de segurança do trabalho'},
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.4 - Planejamento do trabalho',
      'perguntas': [
        {'id': 'ger_4_1', 'texto': 'organização de roteiros racionais e planejamento de tarefas de acordo com o fluxo das demandas'},
        {'id': 'ger_4_2', 'texto': 'análise de itinerários e procedimentos, por mensuração de espaço, distâncias e tempo de execução de tarefas'},
        {'id': 'ger_4_3', 'texto': 'estabelecimento de ritmo constante para realização de tarefas e consecução de resultados dentro das metas pré-estabelecidas'},
        {'id': 'ger_4_4', 'texto': 'exigência de ordem e higiene nos locais de trabalho'},
      ],
    },
    {
      'secao': 'III - Fatores gerenciais da tarefa',
      'subsecao': 'III.5 - Conhecimento técnico das funções',
      'perguntas': [
        {'id': 'ger_5_1', 'texto': 'domínio de conhecimentos na sua área de atuação'},
        {'id': 'ger_5_2', 'texto': 'conhecimento e visão global da estrutura e do funcionamento da organização'},
        {'id': 'ger_5_3', 'texto': 'habilidade no trato do público em geral'},
        {'id': 'ger_5_4', 'texto': 'interpretação e cumprimento de normas e regulamentos'},
        {'id': 'ger_5_5', 'texto': 'observância de prioridades e do interesse público em relação ao trabalho sob sua responsabilidade'},
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
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isAutoavaliacao ? 'Autoavaliação' : 'Avaliação do Gestor',
                style: const TextStyle(fontSize: 20),
              ),
              if (widget.avaliacaoAtual != null && widget.totalAvaliacoes != null)
                Text(
                  'Avaliando ${widget.avaliacaoAtual} de ${widget.totalAvaliacoes}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          backgroundColor: widget.isAutoavaliacao ? Colors.blue : Colors.purple,
          actions: [
            if (!_isReadOnly)
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
                          widget.employeeData['nome']?.toString() ?? '',
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
                                _formatarDataAdmissao(widget.employeeData['data_admissao']),
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
                                widget.employeeData['funcao']?.toString() ?? 'N/A',
                                Icons.work,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Escolaridade',
                                widget.employeeData['escolaridade']?.toString() ?? 'N/A',
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
                                'Situação',
                                SituacaoHelper.getDescricaoCompleta(widget.employeeData['situacao']?.toString()),
                                Icons.info_outline,
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
                                widget.employeeData['nomenivel']?.toString() ??
                                  'Nível ${widget.employeeData['nivel']?.toString() ?? 'N/A'}',
                                Icons.trending_up,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Faixa',
                                widget.employeeData['nomefaixa']?.toString() ??
                                  'Faixa ${widget.employeeData['grau']?.toString() ?? 'N/A'}',
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

            // Exibir Provas (Assinatura e Foto) se for ReadOnly (Comissão visualizando)
            if (_isReadOnly && (_signatureUrl != null || _photoUrl != null))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Avaliação Assinada e Validada',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         if (_photoUrl != null) ...[
                            Column(
                              children: [
                                const Text('Foto do Avaliador', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 100,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _photoUrl!, 
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                         ],
                         if (_signatureUrl != null) ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Assinatura Digital', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _signatureUrl!, 
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                         ],
                      ],
                    ),
                  ],
                ),

              ),
              

              if (_signatureMetadata != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _mostrarDetalhesAssinatura,
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text('Ver Detalhes da Auditoria'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green.shade800,
                      ),
                    ),
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
                      enabled: !_isReadOnly, // Desabilita edição
                      decoration: InputDecoration(
                        hintText: _isReadOnly ? 'Nenhuma observação registrada.' : 'Digite suas observações aqui...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: _isReadOnly,
                        fillColor: _isReadOnly ? Colors.grey.shade100 : null,
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
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey.shade300;
                            }
                            return widget.isAutoavaliacao ? Colors.blue : Colors.purple;
                          }),
                          foregroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey.shade600;
                            }
                            return Colors.white;
                          }),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          elevation: MaterialStateProperty.resolveWith<double>((states) {
                             if (states.contains(MaterialState.disabled)) return 0;
                             return 2; 
                          }),
                        ),
                        onPressed: _isReadOnly
                            ? () => Navigator.pop(context)
                            : (_todasRespondidas && !_isSubmitting
                                ? _salvarAvaliacao
                                : null),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _isReadOnly 
                                    ? 'VOLTAR (AVALIAÇÃO CONCLUÍDA)' 
                                    : (_todasRespondidas
                                        ? 'FINALIZAR AVALIAÇÃO'
                                        : 'RESPONDA TODAS AS PERGUNTAS PARA CONTINUAR'),
                                style: const TextStyle(
                                  fontSize: 14, // Reduzido um pouco para evitar overflow em telas pequenas
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
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
      for (var perguntaMap in secao['perguntas']) {
        final key = perguntaMap['id'] as String;
        final texto = perguntaMap['texto'] as String;
        widgets.add(_buildPergunta(key, texto));
        widgets.add(const SizedBox(height: 20));
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
      onTap: _isReadOnly 
        ? null 
        : () {
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

    // 0. Modal de Confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Avaliação'),
        content: const Text(
          'Deseja realmente finalizar esta avaliação?\n\n'
          'Verifique se as notas e observações estão corretas antes de prosseguir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancelar
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirmar
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }



    // 1. Solicitar Assinatura (apenas se requestSignature for true E não for save without signature)
    String? signatureUrl;
    String status = 'concluida';

    if (widget.allowSaveWithoutSignature) {
       status = 'aguardando_assinatura';
       // Skip signature screen
    } else if (widget.requestSignature) {
      final signatureBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (context) => const SignatureScreen()),
      );

      if (signatureBytes == null) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
        return; // Usuário cancelou
      }

       // 2. Upload da Assinatura
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('signatures')
            .child('auto') // Organizar por tipo
            .child('${widget.chapa}_${DateTime.now().millisecondsSinceEpoch}.png');

        await storageRef.putData(signatureBytes);
        signatureUrl = await storageRef.getDownloadURL();
    }

    try {
      // Obter ciclo atual

      final configDoc = await _firestore.collection('config').doc('general').get();
      final ciclo = configDoc.data()?['currentCycle'] ?? '2026';
      // const ciclo = '2026'; // Hardcode removido
      final ano = ciclo;

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
        'nome': widget.employeeData['nome']?.toString() ?? '',
        'funcao': widget.employeeData['funcao']?.toString() ?? '',
        'nivel': widget.employeeData['nivel']?.toString() ?? '',
        'grau': widget.employeeData['grau']?.toString() ?? '',
        'isManager': widget.employeeData['isManager'] ?? false,
      };

      // 2. Upload da Assinatura para o Storage (já feito acima se necessário)
      // Código movido para bloco condicional anterior
      
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
        'signatureUrl': signatureUrl, // URL da assinatura
        'totalPerguntas': _totalPerguntas,
        'authorMatricula': widget.authorMatricula,
        'employeeSnapshot': employeeSnapshot,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'employeeId': widget.chapa, // Adicionando employeeId para busca correta no Dashboard
      }, SetOptions(merge: true));

      if (mounted) {
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Avaliação salva com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para atualizar o dashboard
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



  void _mostrarDetalhesAssinatura() {
    if (_signatureMetadata == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blue.shade900),
            const SizedBox(width: 8),
            const Text('Auditoria Digital'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetadataRow('IP de Origem', _signatureMetadata!['ip'] ?? 'N/A', Icons.public),
              const Divider(),
              _buildMetadataRow(
                'Geolocalização', 
                _signatureMetadata!['latitude'] != null 
                  ? '${_signatureMetadata!['latitude']}, ${_signatureMetadata!['longitude']}'
                  : 'N/A', 
                Icons.location_on
              ),
              const Divider(),
              _buildMetadataRow('Dispositivo', _signatureMetadata!['device'] ?? 'N/A', Icons.devices),
              const Divider(),
              _buildMetadataRow(
                'Data/Hora (Servidor)', 
                _signatureMetadata!['timestamp'] != null 
                  ? DateFormat('dd/MM/yyyy HH:mm:ss').format((_signatureMetadata!['timestamp'] as Timestamp).toDate())
                  : 'N/A',
                Icons.access_time
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }


  Widget _buildMetadataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatarDataAdmissao(dynamic dataAdmissao) {
    if (dataAdmissao == null) {
      return 'N/A';
    }

    try {
      if (dataAdmissao is Timestamp) {
        final DateTime dateTime = dataAdmissao.toDate();
        return DateFormat('dd/MM/yyyy').format(dateTime);
      } else if (dataAdmissao is String) {
        return dataAdmissao;
      } else {
        return dataAdmissao.toString();
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
