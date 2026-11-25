import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/coin_model.dart';

// Glowing line chart with a price axis on the right and a tag for the
// latest price. Touch or drag on the line to see the price and time.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points, required this.days});

  final List<ChartPoint> points;
  final int days;

  static const height = 240.0;
  static const _bottomReserved = 32.0;
  static const _rightReserved = 60.0;
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _timeLabel(DateTime time) {
    if (days <= 1) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      return '$hour${time.hour < 12 ? 'AM' : 'PM'}';
    }
    final month = _months[time.month - 1];
    if (days <= 90) return '$month ${time.day}';
    return "$month '${(time.year % 100).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final prices = points.map((p) => p.price);
    final minPrice = prices.reduce(min);
    final maxPrice = prices.reduce(max);
    final padding = maxPrice == minPrice
        ? max(maxPrice * 0.01, 0.0001)
        : (maxPrice - minPrice) * 0.1;
    final minY = minPrice - padding;
    final maxY = maxPrice + padding;
    final current = points.last.price;
    final color = changeColor(current - points.first.price);

    // Where the latest price sits, measured from the top of the plot area
    final plotHeight = height - _bottomReserved;
    final currentTop = ((maxY - current) / (maxY - minY) * plotHeight)
        .clamp(0.0, plotHeight);

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              titlesData: _titles(minY, maxY, current),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: current,
                    color: color.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ],
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => darkGreen,
                  tooltipBorder: const BorderSide(color: borderColor),
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        '${formatPrice(points[spot.spotIndex].price)}\n'
                        '${formatDateTime(points[spot.spotIndex].time)}',
                        const TextStyle(color: offWhite, fontSize: 12),
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
                  shadow: Shadow(
                    color: color.withValues(alpha: 0.7),
                    blurRadius: 10,
                  ),
                  dotData: FlDotData(
                    checkToShowDot: (spot, _) => spot.x == points.length - 1,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 4,
                      strokeColor: color.withValues(alpha: 0.3),
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.35),
                        color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: currentTop - 12,
            right: 0,
            width: _rightReserved,
            child: Center(child: _PriceTag(price: current, color: color)),
          ),
        ],
      ),
    );
  }

  // Enough decimals that neighbouring labels never read the same,
  // e.g. a stablecoin moving between 0.995 and 1.005
  static String _axisLabel(double value, double interval) {
    if (value >= 1000) return formatAxisPrice(value);
    final decimals = (2 - (log(interval) / ln10).floor()).clamp(2, 6);
    return value.toStringAsFixed(decimals);
  }

  FlTitlesData _titles(double minY, double maxY, double current) {
    const labelStyle = TextStyle(color: Colors.grey, fontSize: 11);
    final interval = (maxY - minY) / 4;
    return FlTitlesData(
      topTitles: const AxisTitles(),
      leftTitles: const AxisTitles(),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _rightReserved,
          interval: interval,
          getTitlesWidget: (value, meta) {
            // Leave room for the latest-price tag
            if ((value - current).abs() < (maxY - minY) * 0.08) {
              return const SizedBox.shrink();
            }
            // fl_chart also labels min and max; skip a step label that
            // would sit on top of either one
            final isEdge = value == meta.min || value == meta.max;
            if (!isEdge &&
                ((value - meta.min).abs() < interval / 2 ||
                    (meta.max - value).abs() < interval / 2)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(_axisLabel(value, interval), style: labelStyle),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _bottomReserved,
          interval: max(1, (points.length - 1) / 4),
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 || index >= points.length) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
              child: Text(_timeLabel(points[index].time), style: labelStyle),
            );
          },
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.price, required this.color});

  final double price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        formatAxisPrice(price),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
