import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/user_profile.dart';

class WeightGraph extends StatelessWidget {
  final List<UserProfile> profiles;

  const WeightGraph({super.key, required this.profiles});

  @override
  Widget build(BuildContext context) {
    // Take last 7 entries and reverse to show oldest to newest
    final last7 = profiles.take(7).toList().reversed.toList();

    if (last7.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No data available'),
        ),
      );
    }

    // Find min and max weights for better scaling
    final weights = last7.map((p) => p.weightInKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final padding = weightRange * 0.2; // 20% padding

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < last7.length) {
                    final date = last7[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          minX: 0,
          maxX: (last7.length - 1).toDouble(),
          minY: (minWeight - padding).clamp(0, double.infinity),
          maxY: maxWeight + padding,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blue.shade700,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final profile = last7[spot.x.toInt()];
                  return LineTooltipItem(
                    '${profile.weight.toStringAsFixed(1)} ${profile.weightUnit}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: DateFormat('MMM dd').format(profile.date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                last7.length,
                (i) => FlSpot(i.toDouble(), last7[i].weightInKg),
              ),
              isCurved: true,
              color: Colors.blue.shade700,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.blue.shade700,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.shade100.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
