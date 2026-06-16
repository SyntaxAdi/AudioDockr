import 'package:flutter/material.dart';

class WarningFlickerTitle extends StatefulWidget {
  const WarningFlickerTitle({super.key, required this.text});

  final String text;

  @override
  State<WarningFlickerTitle> createState() => _WarningFlickerTitleState();
}

class _WarningFlickerTitleState extends State<WarningFlickerTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  late final Animation<double> _intensity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.82), weight: 18),
    TweenSequenceItem(tween: ConstantTween(0.46), weight: 3),
    TweenSequenceItem(tween: ConstantTween(0.96), weight: 6),
    TweenSequenceItem(tween: ConstantTween(0.68), weight: 3),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 18),
    TweenSequenceItem(tween: ConstantTween(0.58), weight: 2),
    TweenSequenceItem(tween: ConstantTween(0.92), weight: 8),
    TweenSequenceItem(tween: ConstantTween(0.74), weight: 2),
    TweenSequenceItem(tween: ConstantTween(0.98), weight: 16),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dimColor = Color(0xFFFF6B6B);
    const brightColor = Color(0xFFFF3030);

    return AnimatedBuilder(
      animation: _intensity,
      builder: (context, child) {
        final level = _intensity.value;
        final color = Color.lerp(dimColor, brightColor, level) ?? brightColor;

        return Text(
          widget.text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.28 + (level * 0.18)),
                blurRadius: 5 + (level * 6),
              ),
              Shadow(
                color: brightColor.withValues(alpha: 0.12 + (level * 0.12)),
                blurRadius: 14 + (level * 10),
              ),
            ],
          ),
        );
      },
    );
  }
}
