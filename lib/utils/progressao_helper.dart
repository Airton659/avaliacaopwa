/// Regras de progressão usadas na exportação do Excel para o RH.
///
/// Nada aqui é gravado no banco: o direito à progressão é calculado na hora.
class ProgressaoHelper {
  /// Ano a partir do qual a contagem de 3 em 3 anos passa a valer para todos.
  /// Quem entrou em 2009 ou antes tem a base em 2009 (1ª progressão em 2012).
  static const int anoBaseMinimo = 2009;

  /// Nota mínima (exclusiva): as 3 notas do triênio precisam ser MAIORES que isso.
  static const double notaMinima = 70;

  /// Extrai o ano de admissão do texto guardado em Employee.admissao
  /// (dd/MM/yyyy, vindo do Timestamp em UTC) ou de uma data ISO (yyyy-MM-dd...).
  static int? anoAdmissao(String admissao) {
    final texto = admissao.trim();
    if (texto.isEmpty) return null;
    final br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(texto);
    if (br != null) return int.parse(br.group(3)!);
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(texto);
    if (iso != null) return int.parse(iso.group(1)!);
    return null;
  }

  /// Ano-base da contagem: max(ano de admissão, 2009).
  static int anoBase(int anoAdmissao) =>
      anoAdmissao < anoBaseMinimo ? anoBaseMinimo : anoAdmissao;

  /// Verdadeiro se [anoReferencia] é um ano de progressão (base + 3, +6, ...).
  static bool progressaoNoAno(int anoAdmissao, int anoReferencia) {
    final diff = anoReferencia - anoBase(anoAdmissao);
    return diff > 0 && diff % 3 == 0;
  }

  /// Anos das 3 notas do triênio que fecha em [anoReferencia].
  static List<int> anosDoTrienio(int anoReferencia) =>
      [anoReferencia - 2, anoReferencia - 1, anoReferencia];
}
