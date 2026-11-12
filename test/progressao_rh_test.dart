import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sad/utils/progressao_helper.dart';
import 'package:sad/services/excel_rh_service.dart';

void main() {
  test('ano de admissão', () {
    expect(ProgressaoHelper.anoAdmissao('19/05/2014'), 2014);
    expect(ProgressaoHelper.anoAdmissao('2014-05-19 00:00:00.000'), 2014);
    expect(ProgressaoHelper.anoAdmissao(''), isNull);
  });

  test('anos de progressão', () {
    // 2014: 2017, 2020, 2023, 2026
    for (final y in [2017, 2020, 2023, 2026, 2029]) {
      expect(ProgressaoHelper.progressaoNoAno(2014, y), isTrue, reason: '$y');
    }
    expect(ProgressaoHelper.progressaoNoAno(2014, 2025), isFalse);
    expect(ProgressaoHelper.progressaoNoAno(2014, 2014), isFalse);
    // antes de 2009 (e 2009): 2012, 2015, ..., 2024, 2027
    for (final adm in [1986, 2005, 2009]) {
      for (final y in [2012, 2015, 2018, 2021, 2024, 2027]) {
        expect(ProgressaoHelper.progressaoNoAno(adm, y), isTrue, reason: '$adm/$y');
      }
      expect(ProgressaoHelper.progressaoNoAno(adm, 2026), isFalse);
      expect(ProgressaoHelper.progressaoNoAno(adm, 2009), isFalse);
    }
    // 2010: 2013 ...
    expect(ProgressaoHelper.progressaoNoAno(2010, 2013), isTrue);
    expect(ProgressaoHelper.progressaoNoAno(2010, 2025), isTrue);
    expect(ProgressaoHelper.progressaoNoAno(2010, 2026), isFalse);
  });

  test('gera xlsx com filtro', () {
    final bytes = ExcelRhService.gerar([
      const LinhaProgressaoRH(
        chapa: '03106', nome: 'FULANA TESTE', admissao: '19/05/2014',
        funcao: 'AGENTE', nivel: 'PAD N4 - NIVEL I', faixa: 'C', situacao: 'A',
        notas: {2024: 90.0, 2025: 95.5, 2026: 98.5},
        progressao: true,
      ),
      const LinhaProgressaoRH(
        chapa: '00002', nome: 'BELTRANO', admissao: '01/02/2014',
        funcao: 'X', nivel: 'N', faixa: 'A', situacao: 'A',
        notas: {2025: 60.0, 2026: 80.0},
        progressao: false, motivo: 'sem nota em 2024; nota 2025 = 60.0',
      ),
    ], [2024, 2025, 2026]);
    expect(bytes, isNotNull);
    File('${Directory.systemTemp.path}/teste_rh.xlsx').writeAsBytesSync(bytes!);
    print('ARQ: ${Directory.systemTemp.path}/teste_rh.xlsx');
  });
}
