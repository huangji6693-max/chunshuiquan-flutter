import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chunshuiquan_flutter/features/auth/data/auth_repository.dart';
import 'package:chunshuiquan_flutter/features/auth/domain/user_profile.dart';

final currentUserProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(authRepositoryProvider).getMe();
});
