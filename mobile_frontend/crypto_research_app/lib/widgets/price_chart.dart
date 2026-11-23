import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/coin_model.dart';

// Touch or drag on the line to see the price and time
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final prices = points.map((p) => p.price);
    final minPrice = prices.reduce(min);
    final maxPrice = prices.reduce(max);
    final padding = (maxPrice - minPrice) * 0.1;
    final color = changeColor(points.last.price - points.first.price);

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: LineChart(
          LineChartData(
            minY: minPrice - padding,
            maxY: maxPrice + padding,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${formatPrice(points[spot.spotIndex].price)}\n'
                      '${formatDateTime(points[spot.spotIndex].time)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].price),
                ],
                color: color,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
