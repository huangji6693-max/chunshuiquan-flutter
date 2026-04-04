import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/moment_repository.dart';

final momentsTimelineProvider =
    AutoDisposeAsyncNotifierProvider<MomentsNotifier, List<MomentItem>>(MomentsNotifier.new);

class MomentsNotifier extends AutoDisposeAsyncNotifier<List<MomentItem>> {
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<MomentItem>> build() async {
    _page = 0;
    _hasMore = true;
    return _fetch(0);
  }

  Future<List<MomentItem>> _fetch(int page) async {
    final items = await ref.read(momentRepositoryProvider).getTimeline(page: page);
    if (items.length < 20) _hasMore = false;
    return items;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      _page++;
      final older = await _fetch(_page);
      final current = state.valueOrNull ?? [];
      final existingIds = current.map((m) => m.id).toSet();
      final newItems = older.where((m) => !existingIds.contains(m.id)).toList();
      state = AsyncData([...current, ...newItems]);
    } catch (_) {
      _page--;
    } finally {
      _loadingMore = false;
    }
  }
}
