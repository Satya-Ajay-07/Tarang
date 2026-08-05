import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/alert_model.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/repositories/alert_repository.dart';
import 'package:mobile/core/repositories/wave_repository.dart';

// ─── 1. Notifications State ───
class NotificationState {
  final bool isLoading;
  final List<AlertModel> alerts;
  final String? errorMessage;

  const NotificationState({
    required this.isLoading,
    required this.alerts,
    this.errorMessage,
  });

  const NotificationState.initial()
      : isLoading = false,
        alerts = const [],
        errorMessage = null;

  NotificationState copyWith({
    bool? isLoading,
    List<AlertModel>? alerts,
    String? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final AlertRepository _alertRepo;

  NotificationNotifier(this._alertRepo)
      : super(const NotificationState.initial()) {
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _alertRepo.getAlerts(skip: 0, limit: 50);
      state = NotificationState(isLoading: false, alerts: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markRead(String alertId) async {
    final originalAlerts = [...state.alerts];

    // Optimistic Update
    state = state.copyWith(
      alerts: state.alerts
          .map((a) => a.id == alertId ? a.copyWith(isRead: true) : a)
          .toList(),
    );

    try {
      await _alertRepo.markRead(alertId);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(alerts: originalAlerts);
    }
  }

  Future<void> markAllRead() async {
    final originalAlerts = [...state.alerts];

    // Optimistic Update
    state = state.copyWith(
      alerts: state.alerts.map((a) => a.copyWith(isRead: true)).toList(),
    );

    try {
      await _alertRepo.markAllRead();
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(alerts: originalAlerts);
    }
  }

  Future<void> deleteAlert(String alertId) async {
    final originalAlerts = [...state.alerts];

    // Optimistic Update
    state = state.copyWith(
      alerts: state.alerts.where((a) => a.id != alertId).toList(),
    );

    try {
      await _alertRepo.deleteAlert(alertId);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(alerts: originalAlerts);
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final alertRepo = ref.watch(alertRepositoryProvider);
  return NotificationNotifier(alertRepo);
});

// Dynamic Unread Alerts count provider
final unreadCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(notificationProvider).alerts;
  return alerts.where((a) => !a.isRead).length;
});

// ─── 2. Bookmarks State ───
class BookmarkState {
  final bool isLoading;
  final List<WaveModel> bookmarks;
  final String? errorMessage;

  const BookmarkState({
    required this.isLoading,
    required this.bookmarks,
    this.errorMessage,
  });

  const BookmarkState.initial()
      : isLoading = false,
        bookmarks = const [],
        errorMessage = null;

  BookmarkState copyWith({
    bool? isLoading,
    List<WaveModel>? bookmarks,
    String? errorMessage,
  }) {
    return BookmarkState(
      isLoading: isLoading ?? this.isLoading,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final WaveRepository _waveRepo;

  BookmarkNotifier(this._waveRepo) : super(const BookmarkState.initial()) {
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _waveRepo.getBookmarks();
      state = BookmarkState(isLoading: false, bookmarks: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> removeBookmark(String waveId) async {
    final originalBookmarks = [...state.bookmarks];

    // Optimistic Update: instantly remove from list
    state = state.copyWith(
      bookmarks: state.bookmarks.where((b) => b.id != waveId).toList(),
    );

    try {
      await _waveRepo.bookmarkWave(waveId, add: false);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(bookmarks: originalBookmarks);
    }
  }
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  final waveRepo = ref.watch(waveRepositoryProvider);
  return BookmarkNotifier(waveRepo);
});
