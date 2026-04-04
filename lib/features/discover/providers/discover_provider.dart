import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/discover_repository.dart';
import '../domain/swipe_result.dart';
import '../../../core/errors/app_exception.dart';
import '../../../features/auth/domain/user_profile.dart';

/// 筛选参数
class DiscoverFilter {
  final int minAge;
  final int maxAge;
  final double maxDistance;
  final String gender; // '' = 所有人, 'male' = 男, 'female' = 女

  const DiscoverFilter({
    this.minAge = 18,
    this.maxAge = 60,
    this.maxDistance = 50,
    this.gender = '',
  });

  DiscoverFilter copyWith({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    String? gender,
  }) => DiscoverFilter(
    minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge,
    maxDistance: maxDistance ?? this.maxDistance,
    gender: gender ?? this.gender,
  );
}

/// Discover 状态管理
class DiscoverState {
  final List<UserProfile> cards;
  final bool isLoading;
  final SwipeResult? pendingMatch;
  final DiscoverFilter filter;

  const DiscoverState({
    this.cards = const [],
    this.isLoading = false,
    this.pendingMatch,
    this.filter = const DiscoverFilter(),
  });

  DiscoverState copyWith({
    List<UserProfile>? cards,
    bool? isLoading,
    SwipeResult? pendingMatch,
    bool clearMatch = false,
    DiscoverFilter? filter,
  }) =>
      DiscoverState(
        cards: cards ?? this.cards,
        isLoading: isLoading ?? this.isLoading,
        pendingMatch: clearMatch ? null : (pendingMatch ?? this.pendingMatch),
        filter: filter ?? this.filter,
      );
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final Ref _ref;
  bool _fetchingMore = false;
  int _swipedCount = 0;
  int _currentPage = 0;
  bool _hasMore = true;

  DiscoverNotifier(this._ref) : super(const DiscoverState()) {
    _loadFilterAndFetch();
  }

  /// 从本地存储加载筛选参数，然后拉取数据
  Future<void> _loadFilterAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filter = DiscoverFilter(
        minAge: prefs.getInt('filter_minAge') ?? 18,
        maxAge: prefs.getInt('filter_maxAge') ?? 60,
        maxDistance: prefs.getDouble('filter_maxDistance') ?? 50,
        gender: prefs.getString('filter_gender') ?? '',
      );
      state = state.copyWith(filter: filter);
    } catch (_) {
      // 读取失败使用默认值
    }
    _load();
  }

  /// 保存筛选参数到本地存储
  Future<void> _saveFilter(DiscoverFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('filter_minAge', filter.minAge);
      await prefs.setInt('filter_maxAge', filter.maxAge);
      await prefs.setDouble('filter_maxDistance', filter.maxDistance);
      await prefs.setString('filter_gender', filter.gender);
    } catch (_) {
      // 存储失败静默处理
    }
  }

  /// 应用新的筛选条件
  Future<void> refresh() async {
    _swipedCount = 0;
    _currentPage = 0;
    _hasMore = true;
    state = state.copyWith(cards: []);
    await _load();
  }

  Future<void> applyFilter(DiscoverFilter filter) async {
    await _saveFilter(filter);
    _swipedCount = 0;
    _currentPage = 0;
    _hasMore = true;
    state = state.copyWith(filter: filter, cards: []);
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final f = state.filter;
      final profiles = await _ref.read(discoverRepositoryProvider).fetchFeed(
        minAge: f.minAge,
        maxAge: f.maxAge,
        gender: f.gender.isNotEmpty ? f.gender : null,
        maxDistance: f.maxDistance,
        page: 0,
      );
      if (profiles.length < 20) _hasMore = false;
      state = state.copyWith(cards: profiles, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadMore() async {
    if (_fetchingMore || !_hasMore) return;
    _fetchingMore = true;
    try {
      _currentPage++;
      final f = state.filter;
      final more = await _ref.read(discoverRepositoryProvider).fetchFeed(
        minAge: f.minAge,
        maxAge: f.maxAge,
        gender: f.gender.isNotEmpty ? f.gender : null,
        maxDistance: f.maxDistance,
        page: _currentPage,
      );
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        // 去重
        final existingIds = state.cards.map((c) => c.id).toSet();
        final newCards = more.where((c) => !existingIds.contains(c.id)).toList();
        state = state.copyWith(cards: [...state.cards, ...newCards]);
      }
    } catch (_) {
      _currentPage--; // 失败回退
    } finally {
      _fetchingMore = false;
    }
  }

  Future<void> onSwiped(int cardIndex, String direction) async {
    _swipedCount++;
    final remaining = state.cards.length - _swipedCount;
    if (remaining <= 5) _loadMore();

    if (direction == 'nope') {
      if (cardIndex < state.cards.length) {
        _ref.read(discoverRepositoryProvider).sendSwipe(
            state.cards[cardIndex].id, direction);
      }
      return;
    }

    if (cardIndex >= state.cards.length) return;
    try {
      final result = await _ref
          .read(discoverRepositoryProvider)
          .sendSwipe(state.cards[cardIndex].id, direction);
      if (result.matched) {
        state = state.copyWith(pendingMatch: result);
      }
    } on AppException {
      // 静默处理，卡片已滑走
    }
  }

  void dismissMatch() => state = state.copyWith(clearMatch: true);
}

final discoverNotifierProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>(
  (ref) => DiscoverNotifier(ref),
);
