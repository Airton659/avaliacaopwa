import '../models/evaluation.dart';
import '../models/evaluation_type.dart';

class PdfService {
  Future<void> generateAndPrintPdf(
    List<Evaluation> evaluations,
    EvaluationType reportType,
  ) async {
    // Implementação temporária - mostra alerta
    print('PDF gerado para ${evaluations.length} avaliação(ões)');
    print('Tipo: ${reportType.label}');

    // TODO: Implementar geração real de PDF
    // Por enquanto, apenas simula o processo
    await Future.delayed(const Duration(milliseconds: 500));

    throw Exception(
      'Geração de PDF ainda não implementada. '
      'Aguarde a versão completa com suporte a PDF.'
    );
  }
}
