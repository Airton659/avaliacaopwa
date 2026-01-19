class EmployeeSnapshot {
  final String nome;
  final String funcao;
  final String nivel;
  final String faixa;
  final String admissao;

  EmployeeSnapshot({
    required this.nome,
    required this.funcao,
    required this.nivel,
    required this.faixa,
    required this.admissao,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'funcao': funcao,
      'nivel': nivel,
      'faixa': faixa,
      'admissao': admissao,
    };
  }

  factory EmployeeSnapshot.fromMap(Map<String, dynamic> map) {
    return EmployeeSnapshot(
      nome: map['nome'] as String? ?? '',
      funcao: map['funcao'] as String? ?? '',
      nivel: map['nivel'] as String? ?? '',
      faixa: map['faixa'] as String? ?? map['grau'] as String? ?? '',
      admissao: map['admissao'] as String? ?? '',
    );
  }

  factory EmployeeSnapshot.fromEmployee(dynamic employee) {
    return EmployeeSnapshot(
      nome: employee.nome,
      funcao: employee.funcao,
      nivel: employee.nivel,
      faixa: employee.faixa,
      admissao: employee.admissao,
    );
  }
}
