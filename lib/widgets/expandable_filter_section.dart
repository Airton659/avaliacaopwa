import 'package:flutter/material.dart';

class ExpandableFilterSection extends StatelessWidget {
  final String title;
  final int count;
  final Widget child;
  final bool initiallyExpanded;

  const ExpandableFilterSection({
    super.key,
    required this.title,
    required this.child,
    this.count = 0,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: [child],
        ),
      ),
    );
  }
}
