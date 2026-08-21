import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/auth/user_role.dart';
import 'core/auth/user_role_cubit.dart';
import 'core/constants/app_theme/app_theme.dart';
import 'core/constants/app_theme/theme_cubit.dart';
import 'core/constants/app_theme/theme_state.dart';
import 'core/network/token_storage.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/notification_navigation.dart';
import 'core/services/notification_service.dart';
import 'features/home/logic/home_cubit.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/notifications/logic/notifications_cubit.dart';

Future<String> _resolveInitialLocation(SharedPreferences prefs) async {
  final hasToken = await TokenStorage().hasToken();
  if (!hasToken) return AppRoutes.onboarding;

  final role = UserRole.fromString(prefs.getString('user_role'));
  if (role == null) return AppRoutes.onboarding;

  return role.homeRoute;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  final initialMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  final savedRole = prefs.getString('user_role');
  final role = UserRole.fromString(savedRole)?.name ?? UserRole.donor.name;
  final initialLocation = await _resolveInitialLocation(prefs);

  // Background FCM must be registered before runApp.
  await initializeFirebaseApp();
  await NotificationService.ensureAndroidChannel();
  if (NotificationRepository.firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: AtaaApp(
        initialThemeMode: initialMode,
        initialLocation: initialLocation,
        bootstrapRole: role,
      ),
    ),
  );
}

class AtaaApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final String initialLocation;
  final String bootstrapRole;

  const AtaaApp({
    super.key,
    required this.initialThemeMode,
    this.initialLocation = AppRoutes.onboarding,
    required this.bootstrapRole,
  });

  @override
  State<AtaaApp> createState() => _AtaaAppState();
}

class _AtaaAppState extends State<AtaaApp> with WidgetsBindingObserver {
  late final GoRouter _router =
      createAppRouter(initialLocation: widget.initialLocation);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.onNotificationOpened = _onNotificationOpened;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.onAppResumed();
    }
  }

  Future<void> _bootstrapNotifications() async {
    await initializeFirebaseApp();
    await NotificationService.instance.setupFcmTapHandlers();
    await bootstrapFirebase(role: widget.bootstrapRole);
    await NotificationService.instance.setupLocalLaunchHandlers();
  }

  Future<void> _onNotificationOpened(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final fallbackRole = UserRole.fromString(prefs.getString('user_role'));
    final route = NotificationNavigation.resolveRoute(
      data,
      fallbackRole: fallbackRole,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeCubit(initialMode: widget.initialThemeMode),
        ),
        BlocProvider(create: (_) => UserRoleCubit()..loadRole()),
        BlocProvider(create: (_) => HomeCubit()..loadHome()),
        BlocProvider(create: (_) => NotificationsCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            routerConfig: _router,
            title: 'ATAA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeState.mode,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
          );
        },
      ),
    );
  }
}
