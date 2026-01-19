class Question {
  final bool ativo;
  final int ordem;
  final String pergunta;
  final String secao;
  final String subsecao;
  final String tipo; // OPERACIONAL ou GERENCIAL

  Question({
    required this.ativo,
    required this.ordem,
    required this.pergunta,
    required this.secao,
    required this.subsecao,
    required this.tipo,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'ativo': ativo,
      'ordem': ordem,
      'pergunta': pergunta,
      'secao': secao,
      'subsecao': subsecao,
      'tipo': tipo,
    };
  }

  factory Question.fromFirestore(Map<String, dynamic> data) {
    return Question(
      ativo: data['ativo'] as bool? ?? true,
      ordem: data['ordem'] as int? ?? 0,
      pergunta: data['pergunta'] as String? ?? '',
      secao: data['secao'] as String? ?? '',
      subsecao: data['subsecao'] as String? ?? '',
      tipo: data['tipo'] as String? ?? '',
    );
  }
}
