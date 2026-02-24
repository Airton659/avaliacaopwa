class EmployeeWithEvaluations {
  final String chapa;
  final String nome;
  final String funcao;
  final String? nivel;
  final String situacao;
  final bool isManager;
  final Map<String, dynamic>? autoEvaluation;
  final Map<String, dynamic>? gestorEvaluation;
  
  EmployeeWithEvaluations({
    required this.chapa,
    required this.nome,
    required this.funcao,
    this.nivel,
    required this.situacao,
    required this.isManager,
    this.autoEvaluation,
    this.gestorEvaluation,
  });
  
  /// Retorna o status da avaliação: 'concluida', 'parcial', ou 'pendente'
  String get evaluationStatus {
    final autoComplete = autoEvaluation?['status'] == 'concluida';
    final gestorComplete = gestorEvaluation?['status'] == 'concluida';
    
    if (autoComplete && gestorComplete) {
      return 'concluida';
    } else if (autoComplete || gestorComplete) {
      return 'parcial';
    } else {
      return 'pendente';
    }
  }
  
  /// Retorna true se o funcionário tem pelo menos uma avaliação
  bool get hasAnyEvaluation {
    return autoEvaluation != null || gestorEvaluation != null;
  }
  
  /// Retorna a cor do badge de status
  String get statusColor {
    final auto = autoEvaluation?['status'];
    final gestor = gestorEvaluation?['status'];

    if (auto == 'aguardando_assinatura' || gestor == 'aguardando_assinatura') {
      return 'orange'; // Or some other specific color if preferred
    }

    if (gestor == 'aguardando_comissao' || (gestorEvaluation != null && gestorEvaluation!['pdfData'] != null && gestorEvaluation!['pdfData']['ocorrenciaDisciplinar'] == true && gestor != 'concluida')) {
      return 'red';
    }

    switch (evaluationStatus) {
      case 'concluida':
        return 'green';
      case 'parcial':
        return 'orange';
      default:
        return 'red'; // Note: Pendente without evaluations is usually red or orange depending on design
    }
  }
  
  /// Retorna o label do status
  String get statusLabel {
    final auto = autoEvaluation?['status'];
    final gestor = gestorEvaluation?['status'];

    if (auto == 'aguardando_assinatura' || gestor == 'aguardando_assinatura') {
      return 'AGUARDANDO ASSINATURA';
    }

    if (gestor == 'aguardando_comissao' || (gestorEvaluation != null && gestorEvaluation!['pdfData'] != null && gestorEvaluation!['pdfData']['ocorrenciaDisciplinar'] == true && gestor != 'concluida')) {
      return 'AGUARDANDO COMISSAO';
    }

    switch (evaluationStatus) {
      case 'concluida':
        return 'CONCLUÍDO';
      case 'parcial':
        return 'PARCIAL';
      default:
        return 'PENDENTE';
    }
  }
}
