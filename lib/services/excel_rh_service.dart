import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

/// Uma linha da planilha enviada ao RH (quem fecha o triênio no ano).
class LinhaProgressaoRH {
  final String chapa;
  final String nome;
  final String admissao; // dd/MM/yyyy
  final String funcao;
  final String nivel;
  final String faixa;
  final String situacao;
  final Map<int, double> notas; // ano -> nota
  final bool progressao; // tem direito à progressão?
  final String motivo; // por que não tem direito (vazio quando tem)

  const LinhaProgressaoRH({
    required this.chapa,
    required this.nome,
    required this.admissao,
    required this.funcao,
    required this.nivel,
    required this.faixa,
    required this.situacao,
    required this.notas,
    required this.progressao,
    this.motivo = '',
  });
}

/// Gera o .xlsx de progressão para o RH.
class ExcelRhService {
  static const List<String> _cabecalhoFixo = [
    'Nº',
    'CHAPA',
    'NOME',
    'DATA_ADMISSAO',
    'FUNCAO',
    'NOMENIVEL',
    'NOMEFAIXA',
    'CODSITUACAO',
  ];

  /// Colunas: as fixas, NOTA de cada ano, PROGRESSAO (booleana) e MOTIVO.
  /// [anos] são os 3 anos do triênio, em ordem (ex.: 2024, 2025, 2026).
  static List<int>? gerar(List<LinhaProgressaoRH> linhas, List<int> anos) {
    final excel = Excel.createExcel();
    final nomeAba = 'Progressão ${anos.first}-${anos.last}';
    final padrao = excel.getDefaultSheet();
    if (padrao != null) excel.rename(padrao, nomeAba);
    final sheet = excel[nomeAba];

    final totalColunas = _cabecalhoFixo.length + anos.length + 2;

    final estiloTitulo = CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final estiloCabecalho = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF4AA3C7'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Linha 1: título mesclado
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: totalColunas - 1, rowIndex: 0),
      customValue: TextCellValue('TRIÊNIO ${anos.first} A ${anos.last}'),
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = estiloTitulo;

    // Linha 2: cabeçalho
    final cabecalho = [
      ..._cabecalhoFixo,
      for (final a in anos) 'NOTA $a',
      'PROGRESSAO',
      'MOTIVO',
    ];
    for (var c = 0; c < cabecalho.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1),
      );
      cell.value = TextCellValue(cabecalho[c]);
      cell.cellStyle = estiloCabecalho;
    }

    // Linhas de dados
    for (var i = 0; i < linhas.length; i++) {
      final l = linhas[i];
      final r = i + 2;
      final valores = <CellValue?>[
        IntCellValue(i + 1),
        TextCellValue(l.chapa),
        TextCellValue(l.nome),
        _dataOuTexto(l.admissao),
        TextCellValue(l.funcao),
        TextCellValue(l.nivel),
        TextCellValue(l.faixa),
        TextCellValue(l.situacao),
        for (final a in anos)
          l.notas[a] == null ? null : DoubleCellValue(l.notas[a]!),
        BoolCellValue(l.progressao),
        l.motivo.isEmpty ? null : TextCellValue(l.motivo),
      ];
      for (var c = 0; c < valores.length; c++) {
        final v = valores[c];
        if (v == null) continue;
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = v;
      }
    }

    // Larguras
    const larguras = [6.0, 10.0, 42.0, 16.0, 40.0, 22.0, 12.0, 14.0];
    for (var c = 0; c < totalColunas; c++) {
      if (c == totalColunas - 1) {
        sheet.setColumnWidth(c, 60.0); // MOTIVO
      } else {
        sheet.setColumnWidth(c, c < larguras.length ? larguras[c] : 14.0);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) return null;
    return _comFiltro(bytes, 'A2:${_letra(totalColunas - 1)}${linhas.length + 2}');
  }

  static CellValue _dataOuTexto(String texto) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(texto.trim());
    if (m == null) return TextCellValue(texto);
    return DateCellValue(
      year: int.parse(m.group(3)!),
      month: int.parse(m.group(2)!),
      day: int.parse(m.group(1)!),
    );
  }

  static String _letra(int indice) {
    var n = indice;
    var s = '';
    do {
      s = String.fromCharCode(65 + n % 26) + s;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return s;
  }

  /// O pacote `excel` não cria filtro automático; inserimos no XML da aba.
  /// Se algo não sair como esperado, devolve o arquivo original (sem filtro).
  static List<int> _comFiltro(List<int> bytes, String ref) {
    try {
      final zip = ZipDecoder().decodeBytes(bytes);
      final novo = Archive();
      var alterou = false;
      for (final f in zip.files) {
        if (f.isFile && f.name == 'xl/worksheets/sheet1.xml') {
          final xml = utf8.decode(f.content as List<int>);
          if (xml.contains('</sheetData>') && !xml.contains('<autoFilter')) {
            final editado = xml.replaceFirst(
              '</sheetData>',
              '</sheetData><autoFilter ref="$ref"/>',
            );
            final dados = utf8.encode(editado);
            novo.addFile(ArchiveFile(f.name, dados.length, dados));
            alterou = true;
            continue;
          }
        }
        novo.addFile(f);
      }
      if (!alterou) return bytes;
      return ZipEncoder().encode(novo) ?? bytes;
    } catch (_) {
      return bytes;
    }
  }
}
