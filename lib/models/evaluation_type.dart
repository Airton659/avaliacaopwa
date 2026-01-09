enum EvaluationType {
  autoOperacional('AUTO_OPERACIONAL', 'Anexo I - Autoavaliação Operacional'),
  gestorOperacional('GESTOR_OPERACIONAL', 'Anexo II - Avaliação do Gestor (Operacional)'),
  autoGerencial('AUTO_GERENCIAL', 'Anexo IV - Autoavaliação Gerencial'),
  gestorGerencial('GESTOR_GERENCIAL', 'Anexo V - Avaliação do Gestor (Gerencial)'),
  finalOperacional('FINAL_OPERACIONAL', 'Anexo III - Relatório Final (Operacional)'),
  finalGerencial('FINAL_GERENCIAL', 'Anexo VI - Relatório Final (Gerencial)');

  final String code;
  final String label;

  const EvaluationType(this.code, this.label);

  static EvaluationType fromCode(String code) {
    return EvaluationType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => EvaluationType.autoOperacional,
    );
  }
}
