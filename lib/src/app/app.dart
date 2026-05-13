import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/core/startup_demo_fallback_notice.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:eventa/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:eventa/src/features/home/presentation/pages/home_page.dart';
import 'package:eventa/src/features/profile/presentation/pages/edit_profile_page.dart';
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
        builder: (dialogContext) => AlertDialog(
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
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Eventa',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru'), Locale('en')],
        home: const AuthGate(),
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
