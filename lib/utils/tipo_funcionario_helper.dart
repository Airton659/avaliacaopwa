class TipoFuncionarioHelper {
  static const Map<String, String> tipos = {
    'A': 'Autônomo',
    'B': 'Temporário',
    'C': 'Conselheiro',
    'D': 'Diretor',
    'E': 'Estatutário',
    'F': 'Temporário/Comissionista',
    'I': 'Cedido',
    'M': 'Misto',
    'N': 'Normal',
    'O': 'Comissionista',
    'P': 'Temporário',
    'R': 'Rural',
    'S': 'Pensionista',
    'T': 'Estagiário',
    'U': 'Outros',
    'V': 'Contrato verde/Amarelo',
    'W': 'Beneficiário',
    'X': 'Expatriado',
    'Z': 'Aprendiz',
  };

  static String getDescricao(String? codigo) {
    if (codigo == null || codigo.isEmpty) return 'Desconhecido';
    return tipos[codigo.toUpperCase()] ?? codigo;
  }

  static String getDescricaoCompleta(String? codigo) {
    if (codigo == null || codigo.isEmpty) return 'Desconhecido';
    final descricao = tipos[codigo.toUpperCase()];
    if (descricao == null) return codigo;
    return '$codigo - $descricao';
  }
}
