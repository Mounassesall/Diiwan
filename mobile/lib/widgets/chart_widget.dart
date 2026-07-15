import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/diiwan_response.dart';

/// Widget qui affiche un graphique à partir d'un [ChartData].
///
/// - Si [chartData.type] vaut "line", un [LineChart] est rendu.
/// - Si [chartData.type] vaut "bar", un [BarChart] est rendu.
/// - Si chart est null ou type inconnu, rien n'est affiché.
///
/// Chaque fois que le widget est reconstruit avec un nouveau [chartData],
/// une nouvelle clé est utilisée (ValueKey) pour forcer la destruction
/// de l'instance précédente et éviter les fuites mémoire.
class DiiwanChart extends StatelessWidget {
  final ChartData chartData;

  const DiiwanChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    // Clé unique pour forcer la ré-instanciation du widget fl_chart
    final widgetKey = ValueKey('${chartData.type}-${chartData.labels.join("-")}');

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        height: 250,
        child: _buildChart(widgetKey),
      ),
    );
  }

  Widget _buildChart(Key key) {
    switch (chartData.type) {
      case 'line':
        return _buildLineChart(key);
      case 'bar':
        return _buildBarChart(key);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLineChart(Key key) {
    if (chartData.datasets.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    final data = chartData.datasets.first.data;
    for (int i = 0; i < chartData.labels.length && i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return LineChart(
      key: key,
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: Colors.deepPurple,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.deepPurple.withOpacity(0.1),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      chartData.labels[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 44),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  Widget _buildBarChart(Key key) {
    if (chartData.datasets.isEmpty) return const SizedBox.shrink();

    final data = chartData.datasets.first.data;
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < chartData.labels.length && i < data.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i],
              color: Colors.deepPurple,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      key: key,
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      chartData.labels[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 44),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}
