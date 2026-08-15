import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../theme/app_theme.dart';

/// Handwriting exercise (feature 18): trace [letter] over a faint guide.
/// Feedback is a simplified heuristic — stroke count, how much of the
/// canvas the trace covers, and whether the first stroke's net movement
/// trends right-to-left, matching how N'Ko is written — not real
/// handwriting recognition, which would need a trained model and
/// reference stroke data per letter.
class HandwritingCanvas extends StatefulWidget {
  final NkoLetter letter;
  const HandwritingCanvas({super.key, required this.letter});

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  final List<List<Offset>> _strokes = [];
  String? _feedback;
  bool _feedbackGood = false;

  static const _canvasSize = Size(240, 240);

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _strokes.add([d.localPosition]);
      _feedback = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _strokes.last.add(d.localPosition));
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _feedback = null;
    });
  }

  /// N'Ko is written right-to-left, so a well-formed first stroke should
  /// have more net leftward movement than rightward. Compares horizontal
  /// displacement against a small fraction of the canvas width so tiny
  /// jitter within an otherwise-vertical stroke doesn't count against it.
  bool _firstStrokeGoesRightToLeft() {
    final first = _strokes.first;
    if (first.length < 2) return true;
    final dx = first.last.dx - first.first.dx;
    return dx < -_canvasSize.width * 0.05;
  }

  void _checkTrace() {
    if (_strokes.isEmpty) {
      setState(() {
        _feedback = "Trace d'abord la lettre sur le canevas.";
        _feedbackGood = false;
      });
      return;
    }
    var minX = double.infinity, minY = double.infinity, maxX = 0.0, maxY = 0.0;
    for (final stroke in _strokes) {
      for (final p in stroke) {
        minX = p.dx < minX ? p.dx : minX;
        minY = p.dy < minY ? p.dy : minY;
        maxX = p.dx > maxX ? p.dx : maxX;
        maxY = p.dy > maxY ? p.dy : maxY;
      }
    }
    final coverage = ((maxX - minX) * (maxY - minY)) / (_canvasSize.width * _canvasSize.height);
    final rightToLeft = _firstStrokeGoesRightToLeft();
    final good = coverage > 0.12 && _strokes.length <= 6 && rightToLeft;
    setState(() {
      _feedbackGood = good;
      _feedback = good
          ? "Bien tracé — la forme couvre bien l'espace et suit le bon sens."
          : (!rightToLeft
              ? "Le N'Ko s'écrit de droite à gauche — commence ton tracé plus à droite."
              : "Essaie de tracer une lettre plus grande et plus proche du modèle.");
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Trace la lettre ${widget.letter.name} en suivant le modèle",
              textAlign: TextAlign.center, style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Container(
            width: _canvasSize.width,
            height: _canvasSize.height,
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: 0.18,
                    child: Text(widget.letter.char, style: AppText.nko(fontSize: 160), textDirection: TextDirection.rtl),
                  ),
                ),
                GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  child: CustomPaint(
                    size: _canvasSize,
                    painter: _StrokePainter(_strokes),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.ink),
                label: Text("Effacer", style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: _checkTrace,
                icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.indigo),
                label: Text("Vérifier mon tracé",
                    style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.indigo)),
              ),
            ],
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 8),
            Text(_feedback!,
                textAlign: TextAlign.center,
                style: AppText.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _feedbackGood ? AppColors.green : AppColors.clay)),
          ],
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.indigo
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}
