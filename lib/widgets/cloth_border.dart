import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small triangular "bogolan cloth" trim across the top of the home screen.
class ClothBorder extends StatelessWidget {
  const ClothBorder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(20, (i) {
          return Opacity(
            opacity: 0.85,
            child: CustomPaint(
              size: const Size(18, 14),
              painter: _TrianglePainter(color: i.isEven ? AppColors.indigo : AppColors.clay),
            ),
          );
        }),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
