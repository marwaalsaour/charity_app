import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/user_role.dart';
import '../data/models/app_notification_model.dart';
import '../data/repositories/notification_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository.instance,
        super(NotificationsInitial());

  final NotificationRepository _repository;
  StreamSubscription? _subscription;
  NotificationAudience? _audience;

  Future<void> load({required UserRole role}) async {
    emit(NotificationsLoading());
    try {
      _audience = role == UserRole.beneficiary
          ? NotificationAudience.beneficiary
          : NotificationAudience.donor;

      await _subscription?.cancel();
      _subscription = _repository.watchNotifications(_audience!).listen(
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
    if (_audience == null) return;
    await _repository.markAllAsRead(_audience!);
  }

  Future<void> refreshFromServer() async {
    if (_audience == null) return;
    await _repository.syncFromServer(_audience!);
  }

  void resetSession() {
    _subscription?.cancel();
    _subscription = null;
    _audience = null;
    emit(NotificationsInitial());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
