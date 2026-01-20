import 'package:flutter/material.dart';

class PdfHeaderDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const PdfHeaderDialog({Key? key, this.initialData}) : super(key: key);

  @override
  State<PdfHeaderDialog> createState() => _PdfHeaderDialogState();
}

class _PdfHeaderDialogState extends State<PdfHeaderDialog> {
  late String _tipo;
  late bool _ocorrencia;
  late bool _comissionado;
  late bool _disponibilidade;
  late bool _desvio;
  late bool _provimento;
  late bool _condicoes;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _tipo = data['tipoAvaliacao'] ?? 'ADO';
    _ocorrencia = data['ocorrenciaDisciplinar'] ?? false;
    _comissionado = data['empregoComissionado'] ?? false;
    _disponibilidade = data['disponibilidade'] ?? false;
    _desvio = data['desvioFuncao'] ?? false;
    _provimento = data['empregoProvimento'] ?? false;
    _condicoes = data['condicoesAvaliacao'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dados Administrativos - Anexo I', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estes dados são obrigatórios para a geração do Anexo I e devem ser preenchidos antes da avaliação.', 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('ADE'),
                    value: 'ADE',
                    groupValue: _tipo,
                    onChanged: (v) => setState(() => _tipo = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('ADO'),
                    value: 'ADO',
                    groupValue: _tipo,
                    onChanged: (v) => setState(() => _tipo = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text('Ocorrência Disciplinar:', style: TextStyle(fontWeight: FontWeight.bold)),
             Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Sim'),
                    value: true,
                    groupValue: _ocorrencia,
                    onChanged: (v) => setState(() => _ocorrencia = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Não'),
                    value: false,
                    groupValue: _ocorrencia,
                    onChanged: (v) => setState(() => _ocorrencia = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Emprego Comissionado'),
              value: _comissionado,
              onChanged: (v) => setState(() => _comissionado = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Disponibilidade'),
              value: _disponibilidade,
              onChanged: (v) => setState(() => _disponibilidade = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Desvio de Função'),
              value: _desvio,
              onChanged: (v) => setState(() => _desvio = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Emprego de Provimento'),
              value: _provimento,
              onChanged: (v) => setState(() => _provimento = v),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const Text('Tem Condições de Avaliação?', style: TextStyle(fontWeight: FontWeight.bold)),
             Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Sim'),
                    value: true,
                    groupValue: _condicoes,
                    onChanged: (v) => setState(() => _condicoes = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Não'),
                    value: false,
                    groupValue: _condicoes,
                    onChanged: (v) => setState(() => _condicoes = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // No Cancel button, as it's mandatory primarily. 
        // But for "Edit" flow, cancel might be useful.
        // If it's the specific "Edit/Use" flow, the outer logic handles "Use".
        // If it's mandatory, user MUST save to proceed.
        // We'll add Cancel but the caller decides how to handle null.
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
               'tipoAvaliacao': _tipo,
               'ocorrenciaDisciplinar': _ocorrencia,
               'empregoComissionado': _comissionado,
               'disponibilidade': _disponibilidade,
               'desvioFuncao': _desvio,
               'empregoProvimento': _provimento,
               'condicoesAvaliacao': _condicoes,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
