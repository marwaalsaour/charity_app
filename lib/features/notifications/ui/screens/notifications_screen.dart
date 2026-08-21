import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/services/notification_navigation.dart';
import '../../data/models/app_notification_model.dart';
import '../../logic/notifications_cubit.dart';
import '../../logic/notifications_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load(role: widget.role);
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      context.read<NotificationsCubit>().load(role: widget.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('nav_notifications'.tr()),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is! NotificationsLoaded || state.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllAsRead(),
                child: Text('mark_all_read'.tr()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<NotificationsCubit>().load(role: widget.role),
            );
          }

          if (state is NotificationsLoaded) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<NotificationsCubit>().refreshFromServer(),
              child: state.notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.55,
                          child: _EmptyView(role: widget.role),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = state.notifications[index];
                        return _NotificationTile(
                          notification: item,
                          onTap: () {
                            if (!item.isRead) {
                              context.read<NotificationsCubit>().markAsRead(
                                item.id,
                              );
                            }
                            final route = NotificationNavigation.resolveRoute({
                              'type': item.type.firestoreValue,
                              'role': item.audience.storageId,
                            });
                            final current = GoRouterState.of(context).uri.path;
                            if (current != route) {
                              context.go(route);
                            }
                          },
                        );
                      },
                    ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _styleFor(notification.type, cs);

    return Material(
      color: notification.isRead
          ? ext.cardBackground
          : cs.primary.withValues(alpha: isDark ? 0.08 : 0.05),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: notification.isRead
                  ? ext.border
                  : cs.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.hasPlainText
                                ? notification.displayTitle
                                : notification.titleKey.tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.hasPlainText
                          ? notification.displayBody
                          : notification.bodyKey.tr(
                              namedArgs: notification.bodyArgs,
                            ),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: ext.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(fontSize: 11, color: ext.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${'minutes_ago'.tr()}';
    if (diff.inHours < 24) return '${diff.inHours} ${'hours_ago'.tr()}';
    return '${diff.inDays} ${'days_ago'.tr()}';
  }

  _NotificationStyle _styleFor(AppNotificationType type, ColorScheme cs) {
    return switch (type) {
      AppNotificationType.donationSuccess => _NotificationStyle(
          Icons.favorite,
          AppColors.accentDark,
        ),
      AppNotificationType.volunteerSubmitted => _NotificationStyle(
          Icons.volunteer_activism,
          AppColors.primary,
        ),
      AppNotificationType.volunteerApproved => _NotificationStyle(
          Icons.volunteer_activism,
          AppColors.success,
        ),
      AppNotificationType.volunteerRejected => _NotificationStyle(
          Icons.cancel_outlined,
          AppColors.error,
        ),
      AppNotificationType.requestSubmitted => _NotificationStyle(
          Icons.assignment_turned_in_outlined,
          AppColors.primary,
        ),
      AppNotificationType.beneficiaryApproved => _NotificationStyle(
          Icons.check_circle_outline,
          AppColors.success,
        ),
      AppNotificationType.beneficiaryRejected => _NotificationStyle(
          Icons.highlight_off,
          AppColors.error,
        ),
      AppNotificationType.caseFullyFunded => _NotificationStyle(
        Icons.verified_outlined,
        AppColors.success,
      ),
      AppNotificationType.general => _NotificationStyle(
          Icons.notifications_none,
          cs.primary,
        ),
    };
  }
}

class _NotificationStyle {
  const _NotificationStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final descKey = role == UserRole.beneficiary
        ? 'no_notifications_desc_beneficiary'
        : 'no_notifications_desc_donor';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: ext.textSecondary),
            const SizedBox(height: 16),
            Text(
              'no_notifications'.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: ext.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
