import 'package:flutter/material.dart';

/// 滑动标签 overlay
class SwipeLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double opacity;
  final double angle;
  final Alignment alignment;
  final IconData? icon;

  const SwipeLabel({
    super.key,
    required this.text,
    required this.color,
    required this.opacity,
    required this.angle,
    required this.alignment,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            alignment: alignment == Alignment.center
                ? Alignment.center
                : alignment == Alignment.topLeft
                    ? const Alignment(-0.7, -0.7)
                    : const Alignment(0.7, -0.7),
            margin: const EdgeInsets.all(20),
            child: Transform.rotate(
              angle: angle,
              child: icon != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 60, color: color),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: color, width: 4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(text,
                              style: TextStyle(
                                color: color,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              )),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(text,
                          style: TextStyle(
                            color: color,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          )),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
