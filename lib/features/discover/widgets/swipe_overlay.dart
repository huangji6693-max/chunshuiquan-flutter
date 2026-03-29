import 'package:flutter/material.dart';

class SwipeOverlay extends StatelessWidget {
  final bool isLike;
  final double opacity;

  const SwipeOverlay({super.key, required this.isLike, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isLike
                ? [Colors.green.withOpacity(0.15), Colors.transparent]
                : [Colors.red.withOpacity(0.15), Colors.transparent],
            begin: isLike ? Alignment.centerLeft : Alignment.centerRight,
            end: isLike ? Alignment.centerRight : Alignment.centerLeft,
          ),
          border: Border.all(
            color: isLike ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            width: 3,
          ),
        ),
        alignment: isLike ? Alignment.topLeft : Alignment.topRight,
        padding: const EdgeInsets.all(20),
        child: Transform.rotate(
          angle: isLike ? -0.35 : 0.35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isLike
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isLike ? 'LIKE' : 'NOPE',
              style: TextStyle(
                color: isLike
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
