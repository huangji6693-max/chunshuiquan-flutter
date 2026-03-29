import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dating_app/features/auth/data/auth_repository.dart';
import 'package:dating_app/features/auth/domain/user_profile.dart';

final currentUserProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(authRepositoryProvider).getMe();
});
