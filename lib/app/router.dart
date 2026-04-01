import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/splash/presentation/welcome_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/matches/presentation/matches_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/call/presentation/voice_call_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/coins/presentation/coin_shop_screen.dart';
import '../features/vip/presentation/vip_screen.dart';
import '../features/nearby/presentation/nearby_screen.dart';
import '../features/gifts/presentation/gift_history_screen.dart';
import '../features/likes/presentation/likes_screen.dart';
import '../features/moments/presentation/moments_screen.dart';
import '../features/moments/presentation/create_moment_screen.dart';
import '../features/verification/presentation/verification_screen.dart';
import '../core/storage/token_manager.dart';
import '../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);

  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF4D88)),
            const SizedBox(height: 12),
            const Text('页面走丢了', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/discover'),
              child: const Text('回到首页'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      // Splash 和 Welcome 不拦截
      if (loc == '/' || loc == '/welcome') return null;

      final token = await tokenManager.getAccessToken();
      final isLoggedIn = token != null && token.isNotEmpty;
      final isAuthRoute = loc.startsWith('/auth');
      final isOnboarding = loc == '/onboarding';

      // 未登录 → 跳转登录页
      if (!isLoggedIn && !isAuthRoute && !isOnboarding) return '/auth/login';

      // 已登录访问登录页 → 跳转发现页
      if (isLoggedIn && isAuthRoute) return '/discover';

      // 注意：onboarding 检查移到 DiscoverScreen 内部处理
      // 不在 redirect 中做任何网络请求，避免卡死
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/matches', builder: (_, __) => const MatchesScreen()),
          GoRoute(path: '/nearby', builder: (_, __) => const NearbyScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(
            path: '/chat/:matchId',
            builder: (_, state) {
              final matchId = state.pathParameters['matchId']!;
              final extra = state.extra as Map<String, String?>? ?? {};
              return ChatScreen(
                matchId: matchId,
                partnerName: extra['partnerName'],
                partnerAvatarUrl: extra['partnerAvatarUrl'],
              );
            },
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/coins', builder: (_, __) => const CoinShopScreen()),
          GoRoute(path: '/vip', builder: (_, __) => const VipScreen()),
          GoRoute(path: '/gifts/history', builder: (_, __) => const GiftHistoryScreen()),
          GoRoute(path: '/likes', builder: (_, __) => const LikesScreen()),
          GoRoute(path: '/moments', builder: (_, __) => const MomentsScreen()),
          GoRoute(path: '/moments/create', builder: (_, __) => const CreateMomentScreen()),
          GoRoute(path: '/verification', builder: (_, __) => const VerificationScreen()),
          GoRoute(
            path: '/call/:matchId',
            builder: (_, state) {
              final matchId = state.pathParameters['matchId']!;
              final extra = state.extra as Map<String, String?>? ?? {};
              return VoiceCallScreen(
                matchId: matchId,
                partnerName: extra['partnerName'] ?? '',
                partnerAvatarUrl: extra['partnerAvatarUrl'],
              );
            },
          ),
        ],
      ),
    ],
  );
});
