import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/matches/presentation/matches_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../core/storage/auth_storage.dart';
import '../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStorage = ref.watch(authStorageProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final token = await authStorage.getToken();
      final isLoggedIn = token != null && token.isNotEmpty;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/discover';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/matches', builder: (_, __) => const MatchesScreen()),
          GoRoute(
            path: '/chat/:matchId',
            builder: (_, state) => ChatScreen(matchId: state.pathParameters['matchId']!),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
