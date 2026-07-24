import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// EDIT_TARGET: sensor_graph.dart
// EDIT_PURPOSE: Menampilkan grafik line chart sederhana untuk data sensor waktu.
// EDIT_REASON: FSD hanya mengizinkan LineChart untuk SensorGraph dan MiniSensorGraph.
class SensorGraph extends StatelessWidget {
  const SensorGraph({super.key, required this.points, this.compact = false});

  final List<double> points;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: compact ? 72 : 160,
        child: const Center(child: Text('No trend data')),
      );
    }

    final spots = <FlSpot>[
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index]),
    ];

    return SizedBox(
      height: compact ? 72 : 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          gridData: FlGridData(
            show: !compact,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.chartGrid, strokeWidth: 1),
            getDrawingVerticalLine: (_) =>
                const FlLine(color: AppColors.chartGrid, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(show: !compact),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.chartLine,
              barWidth: compact ? 2 : 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.chartLine.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
