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
import '../core/storage/token_manager.dart';
import '../core/providers/current_user_provider.dart';
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
            const Text('页面不存在', style: TextStyle(fontSize: 18)),
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

      // 已登录 → 检查onboarding状态
      if (isLoggedIn && !isOnboarding && !isAuthRoute) {
        try {
          final container = ProviderScope.containerOf(context);
          final userAsync = container.read(currentUserProvider);
          final user = userAsync.valueOrNull;
          if (user != null && !user.onboardingCompleted) {
            return '/onboarding';
          }
        } catch (_) {}
      }

      // 已登录访问登录页 → 跳转发现页
      if (isLoggedIn && isAuthRoute) return '/discover';

      return null;
    },
    routes: [
      // Splash → 自动跳转
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),

      // Auth
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // Main app (带底部导航)
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
