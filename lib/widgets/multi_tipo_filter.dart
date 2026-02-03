import 'package:flutter/material.dart';
import '../utils/tipo_funcionario_helper.dart';

class MultiTipoFilter extends StatelessWidget {
  final Set<String> selectedTipos;
  final Set<String> availableTipos;
  final Function(Set<String>) onChanged;

  const MultiTipoFilter({
    super.key,
    required this.selectedTipos,
    required this.availableTipos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Sort available types by code
    final sortedTipos = availableTipos.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedTipos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  '${selectedTipos.length} selecionado(s)',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => onChanged({}),
                  child: Text(
                    'Limpar',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: sortedTipos.map((tipo) {
            final isSelected = selectedTipos.contains(tipo);
            final descricao = TipoFuncionarioHelper.getDescricao(tipo);
            final label = '$tipo - $descricao';

            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = Set<String>.from(selectedTipos);
                if (selected) {
                  newSelection.add(tipo);
                } else {
                  newSelection.remove(tipo);
                }
                onChanged(newSelection);
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade900 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
