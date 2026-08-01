import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/notification_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository(),
        super(NotificationsInitial());

  final NotificationRepository _repository;
  StreamSubscription? _subscription;
  String? _userId;

  Future<void> load({bool seedDemo = false}) async {
    emit(NotificationsLoading());
    try {
      _userId = await _repository.getOrCreateUserId();
      if (seedDemo) {
        await _repository.seedDemoNotifications(_userId!);
      }

      await _subscription?.cancel();
      _subscription = _repository.watchNotifications(_userId!).listen(
        (items) {
          final unread = items.where((n) => !n.isRead).length;
          emit(NotificationsLoaded(notifications: items, unreadCount: unread));
        },
        onError: (Object e) {
          emit(NotificationsError(e.toString()));
        },
      );
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    await _repository.markAllAsRead(_userId!);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
