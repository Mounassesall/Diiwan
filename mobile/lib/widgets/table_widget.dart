import 'package:flutter/material.dart';
import '../models/diiwan_response.dart';

/// Widget qui affiche les données tabulaires retournées par l'API.
///
/// Utilise un [DataTable] avec des colonnes dynamiques générées
/// à partir des clés du premier [TableRowData].
class DiiwanTable extends StatelessWidget {
  final List<TableRowData> tableRows;

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
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade50),
          columns: columns
              .map((col) => DataColumn(
                    label: Text(
                      col,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
          rows: tableRows
              .map((row) => DataRow(
                    cells: columns
                        .map((col) => DataCell(
                              Text(row.values[col]?.toString() ?? '–'),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
