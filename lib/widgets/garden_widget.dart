import 'dart:math' as math;
import 'package:flutter/material.dart';

class GardenData {
  final double growthLevel;
  final bool showFlowers;
  final bool showBirds;
  final double dailyBudget;
  final double dailySpent;

  const GardenData({
    required this.growthLevel,
    required this.showFlowers,
    required this.showBirds,
    required this.dailyBudget,
    required this.dailySpent,
  });
}

class GardenWidget extends StatefulWidget {
  final GardenData data;
  final VoidCallback? onTap;

  const GardenWidget({super.key, required this.data, this.onTap});

  @override
  State<GardenWidget> createState() => _GardenWidgetState();
}

class _GardenWidgetState extends State<GardenWidget>
    with TickerProviderStateMixin {
  late AnimationController _growthCtrl;
  late Animation<double> _growthAnim;
  late AnimationController _cloudCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _swayCtrl;
  late AnimationController _fireflyCtrl;
  late AnimationController _rippleCtrl;

  double _prevGrowth = 0;
  int _birdPhase = 0;
  int _waterCount = 0;
  final List<_Ripple> _ripples = [];
  final List<_Firefly> _fireflies = [];
  bool _showLevelUp = false;

  @override
  void initState() {
    super.initState();
    _growthCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _growthAnim = CurvedAnimation(parent: _growthCtrl, curve: Curves.easeOutBack);
    _growthCtrl.forward();

    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _swayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _fireflyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initFireflies();

    if (widget.data.showBirds) {
      _startBirdAnimation();
    }
  }

  void _initFireflies() {
    _fireflies.clear();
    final rng = math.Random(42);
    for (int i = 0; i < 8; i++) {
      _fireflies.add(_Firefly(
        x: rng.nextDouble(),
        y: 0.2 + rng.nextDouble() * 0.55,
        size: 1.5 + rng.nextDouble() * 2.5,
        speed: 0.8 + rng.nextDouble() * 1.2,
        phase: rng.nextDouble() * math.pi * 2,
        hue: 50 + rng.nextDouble() * 30,
      ));
    }
  }

  void _startBirdAnimation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _birdPhase = 1);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _birdPhase = 2);
        });
      }
    });
  }

  void _onGardenTap(Offset localPos) {
    setState(() {
      _waterCount++;
      _ripples.add(_Ripple(pos: localPos, time: 0));
    });
    _rippleCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _ripples.removeAt(0));
      }
    });
  }

  @override
  void didUpdateWidget(GardenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final diff = (widget.data.growthLevel - _prevGrowth).abs();
    if (diff > 0.05) {
      _prevGrowth = widget.data.growthLevel;
      _growthCtrl.forward(from: 0);
      _showLevelUp = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showLevelUp = false);
      });
    }
    if (widget.data.showBirds && _birdPhase == 0) {
      _startBirdAnimation();
    }
  }

  @override
  void dispose() {
    _growthCtrl.dispose();
    _cloudCtrl.dispose();
    _shimmerCtrl.dispose();
    _swayCtrl.dispose();
    _fireflyCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerRow(),
              const SizedBox(height: 12),
              _gardenScene(),
              const SizedBox(height: 8),
              _DailyBudgetBar(
                budget: widget.data.dailyBudget,
                spent: widget.data.dailySpent,
              ),
              const SizedBox(height: 6),
              _levelProgressRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.forest, color: Colors.green),
        ),
        const SizedBox(width: 12),
        Text('Your Garden', style: theme.textTheme.titleSmall),
        const Spacer(),
        _growthBadge(),
      ],
    );
  }

  Widget _gardenScene() {
    final theme = Theme.of(context);
    final growth = widget.data.growthLevel * _growthAnim.value;
    return GestureDetector(
      onTapUp: (details) => _onGardenTap(details.localPosition),
      child: SizedBox(
        height: 160,
        child: AnimatedBuilder(
          animation: Listenable.merge([_cloudCtrl, _shimmerCtrl, _swayCtrl, _fireflyCtrl]),
          builder: (context, _) {
            final shimmer = _shimmerCtrl.value;
            final cloudOffset = _cloudCtrl.value;
            final sway = _swayCtrl.value;
            final fireflyGlow = _fireflyCtrl.value;
            final rippleProgress = _rippleCtrl.isAnimating ? _rippleCtrl.value : -1.0;
            return CustomPaint(
              size: Size.infinite,
              painter: _GardenPainter(
                growth: growth.clamp(0.0, 1.0),
                showFlowers: widget.data.showFlowers,
                showBirds: widget.data.showBirds && _birdPhase > 0,
                birdFlap: _birdPhase == 1,
                brightness: theme.brightness,
                cloudOffset: cloudOffset,
                shimmerIntensity: shimmer,
                swayPhase: sway,
                fireflyGlow: fireflyGlow,
                fireflies: _fireflies,
                ripples: _ripples,
                rippleProgress: rippleProgress,
                waterCount: _waterCount,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _levelProgressRow() {
    final growth = widget.data.growthLevel;
    final milestones = [
      (threshold: 0.0, label: 'Seedling', icon: '🌱'),
      (threshold: 0.2, label: 'Sprout', icon: '🌿'),
      (threshold: 0.4, label: 'Growing', icon: '🌳'),
      (threshold: 0.6, label: 'Blooming', icon: '🌸'),
      (threshold: 0.8, label: 'Thriving', icon: '🌟'),
    ];

    final currentLevel = milestones.lastIndexWhere((m) => growth >= m.threshold);
    final nextLevel = currentLevel < milestones.length - 1 ? currentLevel + 1 : null;
    final progressToNext = nextLevel != null
        ? ((growth - milestones[currentLevel].threshold) /
            (milestones[nextLevel].threshold - milestones[currentLevel].threshold))
            .clamp(0.0, 1.0)
        : 1.0;
    final pct = (progressToNext * 100).round();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              milestones[currentLevel].icon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(milestones[currentLevel].label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.colorScheme.onSurface)),
            const Spacer(),
            if (nextLevel != null)
              Text(
                '${milestones[nextLevel].icon} ${milestones[nextLevel].label}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 20,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 8,
                      width: barW,
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: barW * progressToNext,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [Colors.green.shade300, Colors.green.shade600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...milestones.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pos = entry.value.threshold;
                    final x = barW * pos;
                    final isReached = growth >= pos;
                    final isCurrent = idx == currentLevel;
                    return Positioned(
                      left: x - 6,
                      top: isCurrent ? -4 : 1,
                      child: Container(
                        width: isCurrent ? 16 : 6,
                        height: isCurrent ? 16 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isReached
                              ? (isCurrent ? Colors.green.shade600 : Colors.green.shade400)
                              : Colors.grey.shade400,
                          border: isCurrent
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isCurrent
                              ? [BoxShadow(color: Colors.green.shade300.withValues(alpha: 0.5), blurRadius: 4)]
                              : null,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('$pct% to next level',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            const Spacer(),
            if (nextLevel != null)
              Text(
                '${(growth * 100).round()}% overall',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
          ],
        ),
        if (_showLevelUp && nextLevel != null) ...[
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, _) {
              return Opacity(
                opacity: value,
                child: Row(
                  children: [
                    const Icon(Icons.celebration, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Level Up! ${milestones[nextLevel].label} unlocked!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade600),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _growthBadge() {
    final growth = widget.data.growthLevel;
    final idx = growth < 0.2
        ? 0
        : growth < 0.4
            ? 1
            : growth < 0.6
                ? 2
                : growth < 0.8
                    ? 3
                    : 4;
    const labels = ['Seedling', 'Sprout', 'Growing', 'Blooming', 'Thriving'];
    const icons = ['🌱', '🌿', '🌳', '🌸', '🌟'];
    final colors = [Colors.brown, Colors.green.shade300, Colors.green, Colors.teal, Colors.green.shade700];

    final label = labels[idx];
    final icon = icons[idx];
    final color = colors[idx];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Ripple {
  final Offset pos;
  double time;
  _Ripple({required this.pos, required this.time});
}

class _Firefly {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
  final double hue;
  _Firefly({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.hue,
  });
}

class _DailyBudgetBar extends StatelessWidget {
  final double budget;
  final double spent;

  const _DailyBudgetBar({required this.budget, required this.spent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;
    final onTrack = remaining >= 0;
    final barColor = ratio > 0.9 ? Colors.red : ratio > 0.7 ? Colors.orange : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Budget", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            Text(
              onTrack
                  ? '${remaining.toStringAsFixed(0)} left'
                  : '${(-remaining).toStringAsFixed(0)} over',
              style: TextStyle(
                fontSize: 12,
                color: onTrack ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}

class _GardenPainter extends CustomPainter {
  final double growth;
  final bool showFlowers;
  final bool showBirds;
  final bool birdFlap;
  final Brightness brightness;
  final double cloudOffset;
  final double shimmerIntensity;
  final double swayPhase;
  final double fireflyGlow;
  final List<_Firefly> fireflies;
  final List<_Ripple> ripples;
  final double rippleProgress;
  final int waterCount;

  _GardenPainter({
    required this.growth,
    required this.showFlowers,
    required this.showBirds,
    required this.birdFlap,
    required this.brightness,
    required this.cloudOffset,
    required this.shimmerIntensity,
    required this.swayPhase,
    required this.fireflyGlow,
    required this.fireflies,
    required this.ripples,
    required this.rippleProgress,
    required this.waterCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.85;

    _drawSky(canvas, w, h);
    _drawClouds(canvas, w, h);
    _drawGround(canvas, w, groundY, h);

    if (growth > 0.02) {
      _drawTree(canvas, w / 2, groundY, growth, w, h);
    } else {
      _drawSeed(canvas, w / 2, groundY);
    }

    if (showFlowers && growth > 0.3) {
      _drawFlowers(canvas, w, groundY, growth);
    }

    if (growth > 0.6) {
      _drawFireflies(canvas, w, h);
    }

    if (showBirds && growth > 0.4) {
      _drawBirds(canvas, w, h, growth);
    }

    if (rippleProgress >= 0) {
      _drawRipple(canvas);
    }
  }

  void _drawSky(Canvas canvas, double w, double h) {
    final skyRect = Rect.fromLTWH(0, 0, w, h * 0.85);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: brightness == Brightness.dark
          ? [const Color(0xFF1a1a2e), const Color(0xFF2d2d44)]
          : [const Color(0xFF87CEEB), const Color(0xFFE0F7FA)],
    );
    canvas.drawRect(skyRect, Paint()..shader = gradient.createShader(skyRect));
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.6);

    final cloudY = h * 0.08;
    final cloudW = 60.0;
    final cloudH = 20.0;
    final offset = cloudOffset * (w + cloudW * 2) - cloudW;

    for (int c = 0; c < 2; c++) {
      final cx = offset + c * (w * 0.55);
      final cy = cloudY + c * 20.0;
      canvas.drawOval(Rect.fromLTWH(cx, cy, cloudW, cloudH), cloudPaint);
      canvas.drawOval(Rect.fromLTWH(cx + 12, cy - 6, cloudW - 10, cloudH + 4), cloudPaint);
      canvas.drawOval(Rect.fromLTWH(cx + 28, cy - 3, cloudW - 20, cloudH + 2), cloudPaint);
    }
  }

  void _drawGround(Canvas canvas, double w, double groundY, double h) {
    final groundRect = Rect.fromLTWH(0, groundY, w, h - groundY);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: brightness == Brightness.dark
          ? [const Color(0xFF2d5a27), const Color(0xFF1a3a15)]
          : [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
    );
    canvas.drawRect(groundRect, Paint()..shader = gradient.createShader(groundRect));

    final grassPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF3d7a37).withValues(alpha: 0.3)
          : const Color(0xFF66BB6A).withValues(alpha: 0.3);
    for (int i = 0; i < 20; i++) {
      final x = (w / 20) * i + math.Random(i).nextDouble() * 10;
      final swayOffset = math.sin(swayPhase * math.pi * 2 + i * 0.8) * 3;
      final hh = 5 + math.Random(i).nextDouble() * 8;
      canvas.drawLine(
        Offset(x + swayOffset, groundY),
        Offset(x, groundY - hh),
        grassPaint..strokeWidth = 2,
      );
    }
  }

  void _drawTree(Canvas canvas, double cx, double groundY, double growth, double w, double h) {
    final maxTrunkH = h * 0.45;
    final trunkH = maxTrunkH * growth.clamp(0.0, 0.6) * 1.6;
    final trunkW = 8 + growth * 10;

    final trunkPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF5D4037)
          : const Color(0xFF795548)
      ..strokeWidth = trunkW
      ..strokeCap = StrokeCap.round;

    final trunkTop = groundY - trunkH;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, trunkTop), trunkPaint);

    if (growth > 0.15) {
      _drawBranches(canvas, cx, trunkTop, trunkH, growth, false);
      _drawBranches(canvas, cx, trunkTop, trunkH, growth, true);
    }

    final canopyRadius = 20 + growth * 45;
    final canopyCenter = Offset(cx, trunkTop - canopyRadius * 0.3);

    final canopyPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF2E7D32)
          : const Color(0xFF43A047)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(canopyCenter, canopyRadius, canopyPaint);

    final lightPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF388E3C)
          : const Color(0xFF66BB6A);
    canvas.drawCircle(
      Offset(canopyCenter.dx - canopyRadius * 0.3, canopyCenter.dy - canopyRadius * 0.2),
      canopyRadius * 0.6,
      lightPaint,
    );

    final shimmerPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF4CAF50).withValues(alpha: shimmerIntensity * 0.2)
          : const Color(0xFFA5D6A7).withValues(alpha: shimmerIntensity * 0.25);
    canvas.drawCircle(
      Offset(canopyCenter.dx + canopyRadius * 0.1, canopyCenter.dy - canopyRadius * 0.15),
      canopyRadius * 0.5,
      shimmerPaint,
    );

    final darkPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF1B5E20)
          : const Color(0xFF2E7D32);
    canvas.drawCircle(
      Offset(canopyCenter.dx + canopyRadius * 0.25, canopyCenter.dy + canopyRadius * 0.15),
      canopyRadius * 0.5,
      darkPaint,
    );
  }

  void _drawBranches(Canvas canvas, double cx, double trunkTop, double trunkH, double growth, bool right) {
    final branchPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF5D4037)
          : const Color(0xFF6D4C41)
      ..strokeWidth = 3 + growth * 3
      ..strokeCap = StrokeCap.round;

    final dir = right ? 1.0 : -1.0;
    final branchLen = 20 + growth * 30;
    final branchStart = trunkTop + trunkH * (right ? 0.4 : 0.6);
    final endX = cx + dir * branchLen;
    final endY = branchStart - branchLen * 0.3;

    canvas.drawLine(
      Offset(cx, branchStart),
      Offset(endX, endY),
      branchPaint,
    );

    final leafRadius = 8 + growth * 12;
    final leafPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF388E3C)
          : const Color(0xFF66BB6A);
    canvas.drawCircle(Offset(endX, endY), leafRadius, leafPaint);
  }

  void _drawSeed(Canvas canvas, double cx, double groundY) {
    final seedPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF8D6E63)
          : const Color(0xFFA1887F);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY - 4), width: 8, height: 6),
      seedPaint,
    );
    final sproutPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF66BB6A)
          : const Color(0xFF81C784)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final sway = math.sin(swayPhase * math.pi * 2) * 2;
    canvas.drawLine(Offset(cx, groundY - 4), Offset(cx + sway, groundY - 16), sproutPaint);
  }

  void _drawFlowers(Canvas canvas, double w, double groundY, double growth) {
    final count = (growth * 8).round().clamp(1, 6);
    final petalColors = [Colors.pink, Colors.yellow, Colors.purple, Colors.orange, Colors.red, Colors.blue];

    for (int i = 0; i < count; i++) {
      final x = w * 0.15 + (w * 0.7 / count) * i + math.Random(i).nextDouble() * 15;
      final y = groundY - 2 - math.Random(i + 10).nextDouble() * 8;
      final color = petalColors[i % petalColors.length];
      final sway = math.sin(swayPhase * math.pi * 2 + i * 1.2) * 2;

      final stemPaint = Paint()
        ..color = Colors.green.shade700
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x, groundY), Offset(x + sway, y - 8), stemPaint);

      final petalPaint = Paint()..color = color.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(x + sway, y - 8), 3, petalPaint);
      for (int p = 0; p < 5; p++) {
        final angle = (math.pi * 2 / 5) * p;
        canvas.drawCircle(
          Offset(x + sway + math.cos(angle) * 4, y - 8 + math.sin(angle) * 4),
          2,
          petalPaint,
        );
      }
    }
  }

  void _drawBirds(Canvas canvas, double w, double h, double growth) {
    final birdCount = (growth * 3).round().clamp(1, 3);
    final birdPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFF90A4AE)
          : const Color(0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < birdCount; i++) {
      final bx = w * 0.55 + i * 30.0 + math.Random(i + 20).nextDouble() * 20;
      final by = h * 0.15 + math.Random(i + 30).nextDouble() * 40;
      final wingOffset = birdFlap ? 4.0 : 0.0;

      final path = Path();
      path.moveTo(bx, by);
      path.quadraticBezierTo(bx + 8, by - 4 - wingOffset, bx + 16, by);
      path.moveTo(bx, by);
      path.quadraticBezierTo(bx - 8, by - 4 - wingOffset, bx - 16, by);
      canvas.drawPath(path, birdPaint);
    }
  }

  void _drawFireflies(Canvas canvas, double w, double h) {
    for (final f in fireflies) {
      final fx = f.x * w;
      final fy = f.y * h;
      final alpha = ((math.sin(fireflyGlow * math.pi * 2 * f.speed + f.phase) + 1) / 2) * 0.7;
      final glowRadius = f.size * 4;
      final glowPaint = Paint()
        ..color = HSLColor.fromAHSL(alpha * 0.3, f.hue, 1.0, 0.6).toColor();
      canvas.drawCircle(Offset(fx, fy), glowRadius, glowPaint);
      final dotPaint = Paint()
        ..color = HSLColor.fromAHSL(alpha, f.hue, 1.0, 0.7).toColor();
      canvas.drawCircle(Offset(fx, fy), f.size, dotPaint);
    }
  }

  void _drawRipple(Canvas canvas) {
    if (ripples.isEmpty) return;
    final ripple = ripples.first;
    final progress = rippleProgress;

    final maxRadius = 30.0;
    final radius = maxRadius * progress;
    final alpha = (1.0 - progress) * 0.5;

    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(ripple.pos, radius, ripplePaint);
    canvas.drawCircle(ripple.pos, radius * 0.7, ripplePaint..strokeWidth = 1.5);
    canvas.drawCircle(ripple.pos, radius * 0.4, ripplePaint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_GardenPainter old) =>
      old.growth != growth ||
      old.showFlowers != showFlowers ||
      old.showBirds != showBirds ||
      old.birdFlap != birdFlap ||
      old.cloudOffset != cloudOffset ||
      old.shimmerIntensity != shimmerIntensity ||
      old.swayPhase != swayPhase ||
      old.fireflyGlow != fireflyGlow ||
      old.rippleProgress != rippleProgress ||
      old.waterCount != waterCount;
}
