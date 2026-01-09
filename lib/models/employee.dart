class Employee {
  final String id; // CHAPA
  final String nome;
  final String admissao;
  final String funcao;
  final String nivel;
  final String faixa;
  final String situacao;
  final bool isManager;
  final String? managerId;

  Employee({
    required this.id,
    required this.nome,
    required this.admissao,
    required this.funcao,
    required this.nivel,
    required this.faixa,
    required this.situacao,
    this.isManager = false,
    this.managerId,
  });

  bool get isActive => situacao == 'Ativo';

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nome': nome,
      'admissao': admissao,
      'funcao': funcao,
      'nivel': nivel,
      'faixa': faixa,
      'situacao': situacao,
      'isManager': isManager,
      'managerId': managerId,
    };
  }

  factory Employee.fromFirestore(Map<String, dynamic> data) {
    return Employee(
      id: data['id'] as String,
      nome: data['nome'] as String,
      admissao: data['admissao'] as String,
      funcao: data['funcao'] as String,
      nivel: data['nivel'] as String,
      faixa: data['faixa'] as String,
      situacao: data['situacao'] as String,
      isManager: data['isManager'] as bool? ?? false,
      managerId: data['managerId'] as String?,
    );
  }

  Employee copyWith({
    String? id,
    String? nome,
    String? admissao,
    String? funcao,
    String? nivel,
    String? faixa,
    String? situacao,
    bool? isManager,
    String? managerId,
  }) {
    return Employee(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      admissao: admissao ?? this.admissao,
      funcao: funcao ?? this.funcao,
      nivel: nivel ?? this.nivel,
      faixa: faixa ?? this.faixa,
      situacao: situacao ?? this.situacao,
      isManager: isManager ?? this.isManager,
      managerId: managerId ?? this.managerId,
    );
  }
}
