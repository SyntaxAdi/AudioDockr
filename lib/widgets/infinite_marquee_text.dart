import 'package:flutter/material.dart';

class InfiniteMarqueeText extends StatefulWidget {
  const InfiniteMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.gap = 28,
    this.velocity = 28,
  });

  final String text;
  final TextStyle? style;
  final double gap;
  final double velocity;

  @override
  State<InfiniteMarqueeText> createState() => _InfiniteMarqueeTextState();
}

class _InfiniteMarqueeTextState extends State<InfiniteMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _shouldAnimate = false;
  double _cycleWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation({
    required bool shouldAnimate,
    required double cycleWidth,
  }) {
    if (_shouldAnimate == shouldAnimate &&
        (_cycleWidth - cycleWidth).abs() < 0.5) {
      return;
    }

    _shouldAnimate = shouldAnimate;
    _cycleWidth = cycleWidth;

    if (!shouldAnimate || cycleWidth <= 0) {
      _controller.stop();
      return;
    }

    final durationMs = (cycleWidth / widget.velocity * 1000).round();
    _controller.duration = Duration(milliseconds: durationMs);
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final defaultStyle = DefaultTextStyle.of(context).style;
        final effectiveStyle = widget.style != null
            ? defaultStyle.merge(widget.style)
            : defaultStyle;
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: effectiveStyle,
          ),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();

        final textWidth = textPainter.width;
        final shouldAnimate = textWidth > constraints.maxWidth;
        final cycleWidth = textWidth + widget.gap;
        _syncAnimation(
          shouldAnimate: shouldAnimate,
          cycleWidth: cycleWidth,
        );

        if (!shouldAnimate) {
          return Text(
            widget.text,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return ClipRect(
          child: SizedBox(
            height: textPainter.height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final offset = -_controller.value * cycleWidth;
                return Stack(
                  children: [
                    Positioned(
                      left: offset,
                      child: _MarqueeSegment(
                        text: widget.text,
                        style: effectiveStyle,
                        gap: widget.gap,
                      ),
                    ),
                    Positioned(
                      left: offset + cycleWidth,
                      child: _MarqueeSegment(
                        text: widget.text,
                        style: effectiveStyle,
                        gap: widget.gap,
                      ),
                    ),
                    Positioned(
                      left: offset + (cycleWidth * 2),
                      child: _MarqueeSegment(
                        text: widget.text,
                        style: effectiveStyle,
                        gap: widget.gap,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _MarqueeSegment extends StatelessWidget {
  const _MarqueeSegment({
    required this.text,
    required this.style,
    required this.gap,
  });

  final String text;
  final TextStyle? style;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: style,
          maxLines: 1,
        ),
        SizedBox(width: gap),
      ],
    );
  }
}
