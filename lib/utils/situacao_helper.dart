class SituacaoHelper {
  static const Map<String, String> situacoes = {
    'A': 'Ativo',
    'C': 'Contrato de Trabalho Suspenso',
    'D': 'Demitido',
    'E': 'Licença Mater.',
    'F': 'Férias',
    'G': 'Recesso Remunerado de Estagio',
    'I': 'Apos. por Incapacidade Permanente',
    'K': 'Cessão / Requisição',
    'L': 'Licença s/venc',
    'M': 'Serv.Militar',
    'N': 'Mandato Sindical Ônus do Empregador',
    'O': 'Doença Ocupacional',
    'P': 'Af.Previdência',
    'Q': 'Prisão / Cárcere',
    'R': 'Licença Remun.',
    'S': 'Mandato Sindical Ônus do Sindicato',
    'T': 'Af.Ac.Trabalho',
    'U': 'Outros',
    'V': 'Aviso Prévio',
    'W': 'Licença Mater. Compl. 180 dias',
    'X': 'C/Dem.no mês',
    'Y': 'Licença Paternidade',
    'Z': 'Admissão prox.mês',
  };

  static String getDescricao(String? codigo) {
    if (codigo == null || codigo.isEmpty) {
      return 'N/A';
    }
    return situacoes[codigo.toUpperCase()] ?? codigo;
  }

  static String getDescricaoCompleta(String? codigo) {
    if (codigo == null || codigo.isEmpty) {
      return 'N/A';
    }
    final descricao = situacoes[codigo.toUpperCase()];
    if (descricao != null) {
      return '$codigo - $descricao';
    }
    return codigo;
  }
}
