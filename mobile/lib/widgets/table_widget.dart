import 'package:flutter/material.dart';
import '../models/diiwan_response.dart';

/// Widget qui affiche les données tabulaires retournées par l'API.
///
/// Utilise un [DataTable] avec des colonnes dynamiques générées
/// à partir des clés du premier [TableRowData].
class DiiwanTable extends StatelessWidget {
  final List<TableRowData> tableRows;

  static const Map<String, String> _headerLabels = {
    'annee': 'Année',
    'valeur': 'Valeur',
    'region': 'Région',
    'indicateur': 'Indicateur',
  };

  const DiiwanTable({super.key, required this.tableRows});

  @override
  Widget build(BuildContext context) {
    if (tableRows.isEmpty) return const SizedBox.shrink();

    // Extraire les noms de colonnes depuis la première ligne
    final columns = tableRows.first.values.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
            dataRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
            columns: columns
                .map((col) => DataColumn(
                      label: Text(
                        _headerLabels[col] ?? col,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ))
                .toList(),
            rows: tableRows
                .map((row) => DataRow(
                      cells: columns
                          .map((col) => DataCell(
                                Text(row.values[col]?.toString() ?? '–', style: const TextStyle(color: Color(0xFFE2E8F0))),
                              ))
                          .toList(),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
