import 'package:flutter/material.dart';
import '../models/nko_data.dart';
import '../state/challenges.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cloth_border.dart';

class HomeScreen extends StatelessWidget {
  final Progress progress;
  final void Function(NkoUnit unit, bool locked) onStart;
  final VoidCallback onHeartsTap;

  const HomeScreen({super.key, required this.progress, required this.onStart, required this.onHeartsTap});

  @override
  Widget build(BuildContext context) {
    final completed = progress.completedUnits;
    var currentFound = false;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ClothBorder(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("N'Ko Kalan", style: AppText.fraunces(fontSize: 26, letterSpacing: -0.5)),
                            const SizedBox(height: 2),
                            Text("Apprends à lire et écrire le ߒߞߏ",
                                style: AppText.inter(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          _Badge(icon: Icons.military_tech, iconColor: AppColors.gold, label: "Niv. ${levelForXp(progress.xp)}"),
                          const SizedBox(width: 8),
                          _Badge(icon: Icons.local_fire_department, iconColor: AppColors.clay, label: "${progress.streak}"),
                          const SizedBox(width: 8),
                          _Badge(icon: Icons.diamond, iconColor: AppColors.indigo, label: "${progress.gems}"),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onHeartsTap,
                            child: _Badge(
                              icon: Icons.favorite,
                              iconColor: AppColors.clay,
                              label: "${progress.hearts}",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: _ChallengesCard(progress: progress),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: _Path(
                    completed: completed,
                    onStart: onStart,
                    findCurrent: () => currentFound,
                    setCurrent: () => currentFound = true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _Badge({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Daily + weekly challenge progress, rotated deterministically by date —
/// see [dailyChallengeFor]/[weeklyChallengeFor].
class _ChallengesCard extends StatelessWidget {
  final Progress progress;
  const _ChallengesCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daily = dailyChallengeFor(now);
    final weekly = weeklyChallengeFor(now);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChallengeRow(icon: Icons.today, label: daily.title, current: daily.progressFor(progress), target: daily.target),
          const SizedBox(height: 12),
          _ChallengeRow(
              icon: Icons.calendar_view_week, label: weekly.title, current: weekly.progressFor(progress), target: weekly.target),
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int current;
  final int target;
  const _ChallengeRow({required this.icon, required this.label, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final done = current >= target;
    return Row(
      children: [
        Icon(icon, size: 18, color: done ? AppColors.green : AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (current / target).clamp(0, 1),
                  minHeight: 7,
                  backgroundColor: AppColors.lockedNode,
                  valueColor: AlwaysStoppedAnimation(done ? AppColors.green : AppColors.gold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text("${current.clamp(0, target)}/$target",
            style: AppText.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _Path extends StatelessWidget {
  final List<String> completed;
  final void Function(NkoUnit unit, bool locked) onStart;
  final bool Function() findCurrent;
  final VoidCallback setCurrent;

  const _Path({
    required this.completed,
    required this.onStart,
    required this.findCurrent,
    required this.setCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      final isCompleted = completed.contains(unit.id);
      final isLocked = i > 0 && !completed.contains(units[i - 1].id);
      final isCurrent = !isCompleted && !isLocked && !findCurrent();
      if (isCurrent) setCurrent();
      final alignLeft = i.isEven;

      rows.add(_UnitNode(
        index: i,
        unit: unit,
        isCompleted: isCompleted,
        isLocked: isLocked,
        isCurrent: isCurrent,
        alignLeft: alignLeft,
        onTap: () => onStart(unit, isLocked),
      ));
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _ThreadPainter(count: units.length)),
        ),
        Column(children: rows),
      ],
    );
  }
}

class _UnitNode extends StatelessWidget {
  final int index;
  final NkoUnit unit;
  final bool isCompleted;
  final bool isLocked;
  final bool isCurrent;
  final bool alignLeft;
  final VoidCallback onTap;

  const _UnitNode({
    required this.index,
    required this.unit,
    required this.isCompleted,
    required this.isLocked,
    required this.isCurrent,
    required this.alignLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = isCompleted ? AppColors.green : (isLocked ? AppColors.lockedNode : AppColors.indigo);

    Widget nodeIcon;
    if (isCompleted) {
      nodeIcon = const Icon(Icons.check, color: Colors.white, size: 26);
    } else if (isLocked) {
      nodeIcon = const Icon(Icons.lock, color: AppColors.lockedIcon, size: 22);
    } else {
      nodeIcon = Text("${index + 1}", style: AppText.fraunces(fontSize: 22, color: Colors.white));
    }

    final node = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: nodeColor,
        shape: BoxShape.circle,
        boxShadow: isCurrent
            ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 0, spreadRadius: 6)]
            : [const BoxShadow(color: Color(0x26000000), offset: Offset(0, 3))],
      ),
      alignment: Alignment.center,
      child: nodeIcon,
    );

    final label = SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(unit.title,
              textAlign: alignLeft ? TextAlign.left : TextAlign.right,
              style: AppText.inter(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(unit.subtitle,
              textAlign: alignLeft ? TextAlign.left : TextAlign.right,
              style: AppText.inter(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.6))),
        ],
      ),
    );

    final column = Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isCurrent)
              Positioned(
                top: -30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12)),
                  child: Text("Commencer",
                      style: AppText.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            GestureDetector(onTap: isLocked ? null : onTap, child: node),
          ],
        ),
        const SizedBox(height: 8),
        label,
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 46),
      child: Row(
        mainAxisAlignment: alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [column],
      ),
    );
  }
}

/// Dashed winding thread behind the unit nodes — mirrors the SVG path in the
/// original web design (a loose "S" curve down the page).
class _ThreadPainter extends CustomPainter {
  final int count;
  _ThreadPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final segH = size.height / count;
    final midX = size.width / 2;
    path.moveTo(midX, 0);
    for (var i = 0; i < count; i++) {
      final y1 = segH * i + segH * 0.5;
      final y2 = segH * (i + 1);
      final ctrlX = i.isEven ? midX - 100 : midX + 100;
      path.quadraticBezierTo(ctrlX, y1, midX, y2);
    }

    final dashed = _dashPath(path, dashLength: 2, gapLength: 14);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        final next = (distance + len).clamp(0, metric.length);
        if (draw) {
          dest.addPath(metric.extractPath(distance, next.toDouble()), Offset.zero);
        }
        distance = next.toDouble();
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter oldDelegate) => oldDelegate.count != count;
}
