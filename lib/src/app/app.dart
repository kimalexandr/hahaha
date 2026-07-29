import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/core/startup_demo_fallback_notice.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:eventa/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:eventa/src/features/home/presentation/pages/home_page.dart';
import 'package:eventa/src/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:eventa/src/features/push/data/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static const _seedColor = Color(0xFF6D5EF6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = takeStartupDemoFallbackNoticeIfAny();
      if (message == null) return;
      final navContext = _navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      showDialog<void>(
        context: navContext,
        barrierDismissible: true,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Демо-режим'),
              content: SingleChildScrollView(
                child: SelectableText(
                  'Не удалось подключиться к Firebase/Google. '
                  'Включена работа на демо-данных.\n\n'
                  'Причина:\n$message',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            pushNotificationService.start(_navigatorKey);
          } else if (state is Unauthenticated) {
            // Токен чистится в AuthSignOutRequested до signOut.
          }
        },
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Eventa',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F4FF),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white.withValues(alpha: 0.88),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _seedColor.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _seedColor, width: 1.4),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ru'), Locale('en')],
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return FutureBuilder<bool>(
            future: getIt<AuthRepository>().isNewUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        'Ошибка профиля:\n${snapshot.error}',
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data == true) {
                return const EditProfilePage();
              }
              return const HomePage();
            },
          );
        }
        if (state is Unauthenticated) {
          return const SignInPage();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
