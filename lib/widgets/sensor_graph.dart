// EDIT_TARGET: lib/widgets/sensor_graph.dart
// EDIT_PURPOSE: Shows a full sensor trend line chart
// EDIT_REASON: Sensor details need fl_chart visualization while Home controls visibility

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

class SensorGraph extends StatelessWidget {
  const SensorGraph({
    super.key,
    required this.data,
    required this.label,
    required this.unit,
  });

  final List<FlSpot> data;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ($unit)', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: data.isEmpty ? 0 : data.first.x,
                maxX: data.isEmpty ? 1 : data.last.x,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.isEmpty ? const [FlSpot(0, 0)] : data,
                    color: AppColors.chartLine,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.chartGrid, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: _axisLabel,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: _axisLabel,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.chartGrid),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisLabel(double value, TitleMeta meta) {
    return Text(
      value.toStringAsFixed(0),
      style: AppTextStyles.caption.copyWith(color: AppColors.chartText),
    );
  }
}
