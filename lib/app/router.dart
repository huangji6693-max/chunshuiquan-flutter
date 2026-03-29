import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/matches/presentation/matches_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
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
      final token = await tokenManager.getAccessToken();
      final isLoggedIn = token != null && token.isNotEmpty;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthRoute && !isOnboarding) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/discover';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/matches', builder: (_, __) => const MatchesScreen()),
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
        ],
      ),
    ],
  );
});
