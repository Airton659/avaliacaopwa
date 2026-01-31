import 'package:flutter/material.dart';
import '../utils/situacao_helper.dart';

/// Widget reutilizável para filtro multi-seleção de situações
/// Busca dinamicamente as situações disponíveis e permite seleção múltipla via chips
class MultiSituacaoFilter extends StatelessWidget {
  final Set<String> selectedSituacoes;
  final Set<String> availableSituacoes;
  final Function(Set<String>) onChanged;

  const MultiSituacaoFilter({
    super.key,
    required this.selectedSituacoes,
    required this.availableSituacoes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSituacoes = availableSituacoes.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.filter_list, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Filtrar por Situação',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            if (selectedSituacoes.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedSituacoes.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (sortedSituacoes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Nenhuma situação disponível',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Chip "Todas" para limpar seleção
              if (selectedSituacoes.isNotEmpty)
                ActionChip(
                  label: const Text('Limpar filtro'),
                  avatar: const Icon(Icons.clear, size: 16),
                  onPressed: () => onChanged({}),
                  backgroundColor: Colors.grey.shade200,
                ),
              // Chips de situações
              ...sortedSituacoes.map((situacao) {
                final isSelected = selectedSituacoes.contains(situacao);
                final descricao = SituacaoHelper.situacoes[situacao] ?? situacao;

                return FilterChip(
                  label: Text('$situacao - $descricao'),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newSelection = Set<String>.from(selectedSituacoes);
                    if (selected) {
                      newSelection.add(situacao);
                    } else {
                      newSelection.remove(situacao);
                    }
                    onChanged(newSelection);
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.blue.shade900 : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ],
          ),
      ],
    );
  }
}
