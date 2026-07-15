

/// Représente la réponse de l'API Diiwan.
class DiiwanResponse {
  final String answer;
  final List<TableRowData> table;
  final ChartData? chart;
  final Metadata metadata;

  DiiwanResponse({
    required this.answer,
    required this.table,
    this.chart,
    required this.metadata,
  });

  factory DiiwanResponse.fromJson(Map<String, dynamic> json) {
    return DiiwanResponse(
      answer: json['answer'] as String,
      table: (json['table'] as List<dynamic>?)
              ?.map((e) => TableRowData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      chart: json['chart'] != null ? ChartData.fromJson(json['chart']) : null,
      metadata: Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }
}

class TableRowData {
  final Map<String, dynamic> values;

  TableRowData(this.values);

  factory TableRowData.fromJson(Map<String, dynamic> json) => TableRowData(json);
}

class ChartData {
  final String type; // "line" ou "bar"
  final List<String> labels;
  final List<ChartDataset> datasets;

  ChartData({required this.type, required this.labels, required this.datasets});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      type: json['type'] as String,
      labels: List<String>.from(json['labels'] as List),
      datasets: (json['datasets'] as List<dynamic>)
          .map((e) => ChartDataset.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChartDataset {
  final String label;
  final List<double> data;

  ChartDataset({required this.label, required this.data});

  factory ChartDataset.fromJson(Map<String, dynamic> json) {
    return ChartDataset(
      label: json['label'] as String,
      data: (json['data'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class Metadata {
  final bool fictitious;
  final int rowsUsed;

  Metadata({required this.fictitious, required this.rowsUsed});

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      fictitious: json['fictitious'] as bool,
      rowsUsed: json['rows_used'] as int,
    );
  }
}
