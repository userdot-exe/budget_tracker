import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class StripSegment {
  final String label;
  final double value;
  final Color color;

  const StripSegment(this.label, this.value, this.color);
}

/// Builds strip segments from category totals, biggest first.
List<StripSegment> segmentsFromTotals(Map<String, double> totals) {
  final entries = totals.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in entries) StripSegment(e.key, e.value, categoryColor(e.key))];
}

/// The app's signature element: one bar split into category spending,
/// with whatever is left of the budget shown as a hatched gap.
class BudgetStrip extends StatelessWidget {
  const BudgetStrip({
    super.key,
    required this.segments,
    required this.total,
    this.height = 22,
  });

  final List<StripSegment> segments;

  /// The full width of the strip, usually the monthly budget.
  final double total;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spent = segments.fold<double>(0, (sum, s) => sum + s.value);
    final scale = total > spent ? total : spent;
    final remainder = scale - spent;

    final children = <Widget>[];
    void addGap() {
      if (children.isNotEmpty) children.add(SizedBox(width: 2, child: ColoredBox(color: c.surface)));
    }

    if (scale <= 0) {
      children.add(Expanded(child: _Hatch(background: c.surface, line: c.hatch)));
    } else {
      for (final s in segments) {
        addGap();
        children.add(Expanded(
          flex: _flex(s.value, scale),
          child: Tooltip(
            message: '${s.label}: ${peso(s.value)}',
            child: ColoredBox(color: s.color),
          ),
        ));
      }
      if (remainder > 0) {
        addGap();
        children.add(Expanded(
          flex: _flex(remainder, scale),
          child: _Hatch(background: c.surface, line: c.hatch),
        ));
      }
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  int _flex(double value, double scale) {
    final f = (value / scale * 1000).round();
    return f < 1 ? 1 : f;
  }
}

class _Hatch extends StatelessWidget {
  const _Hatch({required this.background, required this.line});

  final Color background;
  final Color line;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HatchPainter(background, line), child: const SizedBox.expand());
}

class _HatchPainter extends CustomPainter {
  _HatchPainter(this.background, this.line);

  final Color background;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1.2;
    for (double x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.background != background || old.line != line;
}

/// Small color key under the strip.
class StripLegend extends StatelessWidget {
  const StripLegend({super.key, required this.segments});

  final List<StripSegment> segments;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final s in segments)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryDot(color: s.color, size: 8),
              const SizedBox(width: 6),
              Text(s.label, style: TextStyle(fontSize: 12.5, color: c.muted)),
            ],
          ),
      ],
    );
  }
}

class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
}
