import 'package:flutter/material.dart';
import '../../auth/domain/user_profile.dart';

/// 卡片信息遮罩层（已集成到 UserCard 中，此文件保留兼容性）
class CardInfoOverlay extends StatelessWidget {
  final UserProfile user;
  const CardInfoOverlay({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha:0.3),
            Colors.black.withValues(alpha:0.85),
          ],
          stops: const [0.2, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.1,
                  )),
              const SizedBox(width: 10),
              if (user.age != null)
                Text('${user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    )),
            ],
          ),
          if (user.city != null && user.city!.isNotEmpty ||
              user.jobTitle != null && user.jobTitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (user.city != null && user.city!.isNotEmpty) ...[
                  const Icon(Icons.location_on_outlined,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 3),
                  Text(user.city!,
                      style: const TextStyle(
                          color: Color(0xB3FFFFFF), fontSize: 15)),
                  const SizedBox(width: 10),
                ],
                if (user.jobTitle != null && user.jobTitle!.isNotEmpty) ...[
                  const Icon(Icons.work_outline,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(user.jobTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xB3FFFFFF), fontSize: 15)),
                  ),
                ],
              ],
            ),
          ],
          if (user.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: user.tags
                    .take(4)
                    .map((tag) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha:0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha:0.35),
                                  width: 0.8),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
