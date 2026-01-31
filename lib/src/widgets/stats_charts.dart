import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/format_utils.dart';

class ChartLegendItem {
  ChartLegendItem({
    required this.color,
    required this.label,
    this.value,
  });

  final Color color;
  final String label;
  final String? value;
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.items,
    this.dotSize = 10,
  });

  final List<ChartLegendItem> items;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            if (item.value != null) ...[
              const SizedBox(width: 6),
              Text(
                item.value!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
}

class ChartSeries {
  ChartSeries({
    required this.values,
    required this.color,
    this.strokeWidth = 2,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
}

class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.series,
    this.height = 160,
    this.baseline,
    this.gridLines = 4,
    this.emptyLabel,
  });

  final List<ChartSeries> series;
  final double height;
  final double? baseline;
  final int gridLines;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || series.every((item) => item.values.isEmpty)) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          series: series,
          baseline: baseline,
          gridLines: gridLines,
          gridColor: theme.colorScheme.outlineVariant.withOpacity(0.35),
          baselineColor: theme.colorScheme.outline.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.series,
    required this.gridLines,
    required this.gridColor,
    required this.baselineColor,
    this.baseline,
  });

  final List<ChartSeries> series;
  final int gridLines;
  final Color gridColor;
  final Color baselineColor;
  final double? baseline;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) {
      return;
    }
    final chartRect = Offset.zero & size;
    final padded = chartRect.deflate(10);
    if (padded.width <= 0 || padded.height <= 0) {
      return;
    }

    var minValue = baseline ?? double.infinity;
    var maxValue = baseline ?? double.negativeInfinity;
    for (final item in series) {
      for (final value in item.values) {
        minValue = math.min(minValue, value);
        maxValue = math.max(maxValue, value);
      }
    }
    if (minValue == double.infinity || maxValue == double.negativeInfinity) {
      return;
    }
    if ((maxValue - minValue).abs() < 0.0001) {
      minValue -= 1;
      maxValue += 1;
    }
    final range = maxValue - minValue;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= gridLines; i++) {
      final t = i / gridLines;
      final y = padded.bottom - padded.height * t;
      canvas.drawLine(Offset(padded.left, y), Offset(padded.right, y), gridPaint);
    }

    if (baseline != null) {
      final baselineY =
          padded.bottom - ((baseline! - minValue) / range) * padded.height;
      final baselinePaint = Paint()
        ..color = baselineColor
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(padded.left, baselineY),
        Offset(padded.right, baselineY),
        baselinePaint,
      );
    }

    for (final item in series) {
      final values = item.values;
      if (values.isEmpty) {
        continue;
      }
      final linePaint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = item.strokeWidth
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final t = values.length == 1 ? 0.5 : i / (values.length - 1);
        final x = padded.left + padded.width * t;
        final y =
            padded.bottom - ((values[i] - minValue) / range) * padded.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.baseline != baseline ||
        oldDelegate.gridLines != gridLines ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.baselineColor != baselineColor;
  }
}

class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    this.height = 140,
    this.highlightIndex,
    this.barColor,
    this.highlightColor,
    this.gridLines = 4,
    this.emptyLabel,
  });

  final List<double> values;
  final double height;
  final int? highlightIndex;
  final Color? barColor;
  final Color? highlightColor;
  final int gridLines;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BarChartPainter(
          values: values,
          highlightIndex: highlightIndex,
          barColor: barColor ?? theme.colorScheme.primary,
          highlightColor: highlightColor ?? theme.colorScheme.secondary,
          gridLines: gridLines,
          gridColor: theme.colorScheme.outlineVariant.withOpacity(0.35),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.barColor,
    required this.highlightColor,
    required this.gridLines,
    required this.gridColor,
    this.highlightIndex,
  });

  final List<double> values;
  final Color barColor;
  final Color highlightColor;
  final int gridLines;
  final Color gridColor;
  final int? highlightIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    final chartRect = Offset.zero & size;
    final padded = chartRect.deflate(10);
    if (padded.width <= 0 || padded.height <= 0) {
      return;
    }

    var maxValue = values.reduce(math.max);
    if (maxValue <= 0) {
      maxValue = 1;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= gridLines; i++) {
      final t = i / gridLines;
      final y = padded.bottom - padded.height * t;
      canvas.drawLine(Offset(padded.left, y), Offset(padded.right, y), gridPaint);
    }

    final barWidth = padded.width / (values.length * 1.6);
    final gap = barWidth * 0.6;
    final totalWidth =
        values.length * barWidth + (values.length - 1) * gap;
    final startX = padded.left + (padded.width - totalWidth) / 2;

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final barHeight = (value / maxValue) * padded.height;
      final x = startX + i * (barWidth + gap);
      final rect =
          Rect.fromLTWH(x, padded.bottom - barHeight, barWidth, barHeight);
      final paint = Paint()
        ..color = (highlightIndex != null && i == highlightIndex)
            ? highlightColor
            : barColor.withOpacity(0.85);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.gridLines != gridLines ||
        oldDelegate.gridColor != gridColor;
  }
}

class StackedBarValue {
  StackedBarValue({required this.base, required this.top});

  final double base;
  final double top;

  double get total => base + top;
}

class StackedBarChart extends StatelessWidget {
  const StackedBarChart({
    super.key,
    required this.values,
    this.height = 140,
    required this.baseColor,
    required this.topColor,
    this.gridLines = 4,
    this.emptyLabel,
  });

  final List<StackedBarValue> values;
  final double height;
  final Color baseColor;
  final Color topColor;
  final int gridLines;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _StackedBarChartPainter(
          values: values,
          baseColor: baseColor,
          topColor: topColor,
          gridLines: gridLines,
          gridColor: theme.colorScheme.outlineVariant.withOpacity(0.35),
        ),
      ),
    );
  }
}

class _StackedBarChartPainter extends CustomPainter {
  _StackedBarChartPainter({
    required this.values,
    required this.baseColor,
    required this.topColor,
    required this.gridLines,
    required this.gridColor,
  });

  final List<StackedBarValue> values;
  final Color baseColor;
  final Color topColor;
  final int gridLines;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    final chartRect = Offset.zero & size;
    final padded = chartRect.deflate(10);
    if (padded.width <= 0 || padded.height <= 0) {
      return;
    }

    var maxValue = values.map((item) => item.total).fold<double>(0, math.max);
    if (maxValue <= 0) {
      maxValue = 1;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= gridLines; i++) {
      final t = i / gridLines;
      final y = padded.bottom - padded.height * t;
      canvas.drawLine(Offset(padded.left, y), Offset(padded.right, y), gridPaint);
    }

    final barWidth = padded.width / (values.length * 1.6);
    final gap = barWidth * 0.6;
    final totalWidth =
        values.length * barWidth + (values.length - 1) * gap;
    final startX = padded.left + (padded.width - totalWidth) / 2;

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final totalHeight = (value.total / maxValue) * padded.height;
      final baseHeight = (value.base / maxValue) * padded.height;
      final topHeight = totalHeight - baseHeight;
      final x = startX + i * (barWidth + gap);

      if (baseHeight > 0) {
        final rect = Rect.fromLTWH(
          x,
          padded.bottom - baseHeight,
          barWidth,
          baseHeight,
        );
        final rrect = RRect.fromRectAndCorners(
          rect,
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
          topLeft: topHeight <= 0 ? const Radius.circular(6) : Radius.zero,
          topRight: topHeight <= 0 ? const Radius.circular(6) : Radius.zero,
        );
        final paint = Paint()..color = baseColor.withOpacity(0.88);
        canvas.drawRRect(rrect, paint);
      }

      if (topHeight > 0) {
        final rect = Rect.fromLTWH(
          x,
          padded.bottom - totalHeight,
          barWidth,
          topHeight,
        );
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        final paint = Paint()..color = topColor.withOpacity(0.88);
        canvas.drawRRect(rrect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.topColor != topColor ||
        oldDelegate.gridLines != gridLines ||
        oldDelegate.gridColor != gridColor;
  }
}

class DonutSegment {
  DonutSegment({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.height = 180,
    this.centerLabel,
    this.emptyLabel,
  });

  final List<DonutSegment> segments;
  final double height;
  final String? centerLabel;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _DonutChartPainter(
              segments: segments,
              trackColor: theme.colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ),
          if (centerLabel != null)
            Text(
              centerLabel!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.segments,
    required this.trackColor,
  });

  final List<DonutSegment> segments;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) {
      return;
    }
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) {
      return;
    }
    final shortest = math.min(size.width, size.height);
    final strokeWidth = shortest * 0.16;
    final radius = shortest / 2 - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweep = segment.value / total * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.trackColor != trackColor;
  }
}

class ScatterPoint {
  ScatterPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class ScatterChart extends StatelessWidget {
  const ScatterChart({
    super.key,
    required this.points,
    this.height = 180,
    this.pointColor,
    this.emptyLabel,
  });

  final List<ScatterPoint> points;
  final double height;
  final Color? pointColor;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final theme = Theme.of(context);
    final maxX = math
        .max(24 * 60, points.map((p) => p.x).fold<double>(0, math.max))
        .toDouble();
    final maxY = math
        .max(24 * 60, points.map((p) => p.y).fold<double>(0, math.max))
        .toDouble();
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _ScatterChartPainter(
          points: points,
          maxX: maxX,
          maxY: maxY,
          pointColor: pointColor ?? theme.colorScheme.secondary,
          gridColor: theme.colorScheme.outlineVariant.withOpacity(0.35),
        ),
      ),
    );
  }
}

class _ScatterChartPainter extends CustomPainter {
  _ScatterChartPainter({
    required this.points,
    required this.maxX,
    required this.maxY,
    required this.pointColor,
    required this.gridColor,
  });

  final List<ScatterPoint> points;
  final double maxX;
  final double maxY;
  final Color pointColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }
    final chartRect = Offset.zero & size;
    final padded = chartRect.deflate(12);
    if (padded.width <= 0 || padded.height <= 0) {
      return;
    }

    const gridHours = [0, 6, 12, 18, 24];
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final hour in gridHours) {
      final x = padded.left + (hour * 60) / maxX * padded.width;
      canvas.drawLine(Offset(x, padded.top), Offset(x, padded.bottom), gridPaint);
      final y = padded.bottom - (hour * 60) / maxY * padded.height;
      canvas.drawLine(Offset(padded.left, y), Offset(padded.right, y), gridPaint);
    }

    final paint = Paint()
      ..color = pointColor.withOpacity(0.75)
      ..style = PaintingStyle.fill;
    for (final point in points) {
      final x = padded.left + (point.x / maxX) * padded.width;
      final y = padded.bottom - (point.y / maxY) * padded.height;
      canvas.drawCircle(Offset(x, y), 3.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxX != maxX ||
        oldDelegate.maxY != maxY ||
        oldDelegate.pointColor != pointColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.weeks,
    this.maxCellSize = 16,
    this.cellSpacing = 4,
    this.baseColor,
    this.emptyLabel,
  });

  final List<List<int>> weeks;
  final double maxCellSize;
  final double cellSpacing;
  final Color? baseColor;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final flattened = weeks.expand((item) => item).toList();
    final maxValue = flattened.isEmpty
        ? 0
        : flattened.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final theme = Theme.of(context);
    final color = baseColor ?? theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = weeks.length;
        final available =
            constraints.maxWidth - cellSpacing * (columns - 1);
        final cellSize = math.min(maxCellSize, available / columns);
        final height = cellSize * 7 + cellSpacing * 6;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(columns, (colIndex) {
                  final column = weeks[colIndex];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: colIndex == columns - 1 ? 0 : cellSpacing,
                    ),
                    child: Column(
                      children: List.generate(7, (rowIndex) {
                        final value =
                            rowIndex < column.length ? column[rowIndex] : 0;
                        final intensity = maxValue == 0
                            ? 0.0
                            : value.toDouble() / maxValue;
                        final cellColor = Color.lerp(
                          color.withOpacity(0.1),
                          color.withOpacity(0.9),
                          intensity,
                        );
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: EdgeInsets.only(
                            bottom: rowIndex == 6 ? 0 : cellSpacing,
                          ),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '0h',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDuration(Duration(minutes: maxValue)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class HistogramChart extends StatelessWidget {
  const HistogramChart({
    super.key,
    required this.buckets,
    required this.labels,
    this.height = 140,
    this.color,
    this.emptyLabel,
  });

  final List<int> buckets;
  final List<String> labels;
  final double height;
  final Color? color;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty || buckets.every((value) => value == 0)) {
      return ChartEmptyState(label: emptyLabel ?? 'No data');
    }
    final theme = Theme.of(context);
    final maxValue = buckets.reduce(math.max);
    final barColor = color ?? theme.colorScheme.primary;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(buckets.length, (index) {
          final value = buckets[index];
          final factor = maxValue == 0 ? 0.0 : value / maxValue;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == buckets.length - 1 ? 0 : 6,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: factor,
                        widthFactor: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[index],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ChartEmptyState extends StatelessWidget {
  const ChartEmptyState({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
      ),
    );
  }
}
