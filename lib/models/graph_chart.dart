import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forex_calculator/models/forex_price_data.dart';

class MiniSparklineChart extends StatelessWidget {
  final List<PricePoint> priceHistory;
  final bool isSelected;
  final Color color;

  const MiniSparklineChart({
    Key? key,
    required this.priceHistory,
    required this.isSelected,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If we don't have at least 2 points, return an empty container
    if (priceHistory.length < 2) {
      return SizedBox(height: 30);
    }

    // Get min and max values for Y axis scaling
    double minY = double.infinity;
    double maxY = -double.infinity;
    
    for (var point in priceHistory) {
      if (point.price < minY) minY = point.price;
      if (point.price > maxY) maxY = point.price;
    }
    
    // Add a small buffer to min/max
    final yDiff = maxY - minY;
    minY = minY - (yDiff * 0.1);
    maxY = maxY + (yDiff * 0.1);
    
    // Create spot data for the line chart
    final spots = priceHistory.asMap().entries.map((entry) {
      // Use the index as X value to create an evenly spaced chart
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    return SizedBox(
      height: 30,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.2),
              ),
            ),
          ],
          minX: 0,
          maxX: (priceHistory.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }
}