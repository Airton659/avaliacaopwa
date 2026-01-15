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
  final String? password;
  final bool isFirstAccess;

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
    this.password,
    this.isFirstAccess = true,
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
      'password': password,
      'isFirstAccess': isFirstAccess,
    };
  }

  factory Employee.fromFirestore(Map<String, dynamic> data, {String? documentId}) {
    return Employee(
      id: documentId ?? data['id']?.toString() ?? '',
      nome: data['nome']?.toString() ?? '',
      admissao: data['admissao']?.toString() ?? '',
      funcao: data['funcao']?.toString() ?? '',
      nivel: data['nivel']?.toString() ?? '',
      faixa: data['faixa']?.toString() ?? '',
      situacao: data['situacao']?.toString() ?? '',
      isManager: data['isManager'] as bool? ?? false,
      managerId: data['managerId'] as String?,
      password: data['password'] as String?,
      isFirstAccess: data['isFirstAccess'] as bool? ?? true,
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
    String? password,
    bool? isFirstAccess,
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
      password: password ?? this.password,
      isFirstAccess: isFirstAccess ?? this.isFirstAccess,
    );
  }
}
