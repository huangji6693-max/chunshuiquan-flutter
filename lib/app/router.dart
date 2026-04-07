import '../shared/theme/design_tokens.dart';
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
import '../features/settings/presentation/legal_page.dart';
import '../features/profile/presentation/user_detail_screen.dart';
import '../features/discover/domain/user_profile.dart';
import '../core/storage/token_manager.dart';
import '../shared/widgets/main_scaffold.dart';

/// 统一 fadeSlide 过渡页面
CustomTransitionPage<T> _fadeSlide<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);

  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Dt.pink),
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
      GoRoute(
        path: '/',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: LoginScreen(prefilledEmail: state.uri.queryParameters['email']),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      ),
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
            pageBuilder: (_, state) {
              final matchId = state.pathParameters['matchId']!;
              final extra = state.extra as Map<String, String?>? ?? {};
              return _fadeSlide(state, ChatScreen(
                matchId: matchId,
                partnerName: extra['partnerName'],
                partnerAvatarUrl: extra['partnerAvatarUrl'],
              ));
            },
          ),
          GoRoute(path: '/profile', pageBuilder: (_, state) => _fadeSlide(state, const ProfileScreen())),
          GoRoute(path: '/settings', pageBuilder: (_, state) => _fadeSlide(state, const SettingsScreen())),
          GoRoute(path: '/coins', pageBuilder: (_, state) => _fadeSlide(state, const CoinShopScreen())),
          GoRoute(path: '/vip', pageBuilder: (_, state) => _fadeSlide(state, const VipScreen())),
          GoRoute(path: '/gifts/history', pageBuilder: (_, state) => _fadeSlide(state, const GiftHistoryScreen())),
          GoRoute(path: '/likes', pageBuilder: (_, state) => _fadeSlide(state, const LikesScreen())),
          GoRoute(path: '/moments', builder: (_, __) => const MomentsScreen()),
          GoRoute(path: '/moments/create', pageBuilder: (_, state) => _fadeSlide(state, const CreateMomentScreen())),
          GoRoute(path: '/verification', pageBuilder: (_, state) => _fadeSlide(state, const VerificationScreen())),
          GoRoute(
            path: '/call/:matchId',
            pageBuilder: (_, state) {
              final matchId = state.pathParameters['matchId']!;
              final extra = state.extra as Map<String, String?>? ?? {};
              return _fadeSlide(state, VoiceCallScreen(
                matchId: matchId,
                partnerName: extra['partnerName'] ?? '',
                partnerAvatarUrl: extra['partnerAvatarUrl'],
              ));
            },
          ),
          GoRoute(
            path: '/legal/:type',
            pageBuilder: (_, state) {
              final type = state.pathParameters['type']!;
              final isPrivacy = type == 'privacy';
              return _fadeSlide(state, LegalPage(
                title: isPrivacy ? '隐私政策' : '用户协议',
                content: isPrivacy ? PrivacyContent.privacy : PrivacyContent.terms,
              ));
            },
          ),
          GoRoute(
            path: '/user-detail',
            pageBuilder: (_, state) {
              final user = state.extra as UserProfile;
              return _fadeSlide(state, UserDetailScreen(user: user));
            },
          ),
        ],
      ),
    ],
  );
});
