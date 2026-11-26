import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';

const tourSeenKey = 'tour_seen';

// One stop in the tour: the widget to highlight and what to say about it
class TourStep {
  const TourStep({
    required this.target,
    required this.title,
    required this.text,
    this.onShow,
    this.onHide,
  });

  final GlobalKey target;
  final String title;
  final String text;

  // Optional hooks, e.g. to play a demo animation while this step is showing
  final VoidCallback? onShow;
  final VoidCallback? onHide;
}

// First-run guided tour: dims the screen, cuts a glowing hole around each
// step's widget and shows a tip card next to it.
class AppTour {
  static OverlayEntry? _entry;

  // Shows the tour once per install; later calls do nothing
  static Future<void> showOnce(BuildContext context, List<TourStep> steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(tourSeenKey) ?? false) return;
    } catch (_) {
      // Storage unavailable: show the tour anyway
    }
    if (context.mounted) show(context, steps);
  }

  static void show(BuildContext context, List<TourStep> steps) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => _TourOverlay(steps: steps, onFinish: _finish),
    );
    Overlay.of(context).insert(_entry!);
  }

  static Future<void> _finish() async {
    _entry?.remove();
    _entry = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(tourSeenKey, true);
    } catch (_) {
      // The tour will just show again next launch
    }
  }
}

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.onFinish});

  final List<TourStep> steps;
  final VoidCallback onFinish;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;
  bool _shown = false;

  void _hideCurrent() {
    if (_shown) widget.steps[_index].onHide?.call();
    _shown = false;
  }

  void _finish() {
    _hideCurrent();
    widget.onFinish();
  }

  // Screen rect of a step's widget, or null if it isn't on screen
  Rect? _rectOf(TourStep step) {
    final box = step.target.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  // Skips steps whose widget isn't visible right now
  void _goTo(int index) {
    _hideCurrent();
    while (index < widget.steps.length && _rectOf(widget.steps[index]) == null) {
      index++;
    }
    if (index >= widget.steps.length) {
      widget.onFinish();
    } else {
      setState(() {
        _index = index;
        _shown = true;
      });
      widget.steps[index].onShow?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final target = _rectOf(step);
    if (target == null) return const SizedBox.shrink();

    final hole = target.inflate(6);
    final screen = MediaQuery.sizeOf(context);
    final placeBelow = hole.center.dy < screen.height / 2;
    final isLast = _index == widget.steps.length - 1;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Tapping the dimmed area moves to the next tip
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _goTo(_index + 1),
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(end: hole),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (_, rect, _) =>
                    CustomPaint(painter: _SpotlightPainter(rect ?? hole)),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: placeBelow ? hole.bottom + 14 : null,
            bottom: placeBelow ? null : screen.height - hole.top + 14,
            child: _TipCard(
              key: ValueKey(_index),
              step: step,
              stepLabel: '${_index + 1} of ${widget.steps.length}',
              isLast: isLast,
              onSkip: _finish,
              onNext: () => _goTo(_index + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole);

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(16));
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.78));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = neonGreen.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = neonGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    super.key,
    required this.step,
    required this.stepLabel,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
  });

  final TourStep step;
  final String stepLabel;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
        decoration: BoxDecoration(
          color: darkGreen,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: emeraldGreen.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stepLabel,
              style: const TextStyle(fontSize: 12, color: emeraldGreen),
            ),
            const SizedBox(height: 4),
            Text(
              step.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                step.text,
                style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (!isLast)
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text('Skip'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  child: Text(isLast ? 'Got it' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
