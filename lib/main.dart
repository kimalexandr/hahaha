import 'dart:async';

import 'package:eventa/src/app/app.dart';
import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/crash/crash_reporting.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/data/google_sign_in_helper.dart';
import 'package:eventa/src/core/startup_demo_fallback_notice.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(
    () async {
      try {
        await _bootstrap();
        runApp(const App());
      } catch (error, stackTrace) {
        await _reportStartupFailure(error, stackTrace);
        runApp(StartupErrorApp(error: error, stackTrace: stackTrace));
      }
    },
    (error, stackTrace) {
      _reportStartupFailureSync(error, stackTrace);
      runApp(StartupErrorApp(error: error, stackTrace: stackTrace));
    },
  );
}

bool get _firebaseInitialized => Firebase.apps.isNotEmpty;

Future<void> _reportStartupFailure(Object error, StackTrace stackTrace) async {
  if (!_crashlyticsAvailable || !_firebaseInitialized) return;
  try {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'bootstrap',
      fatal: true,
    );
    await FirebaseCrashlytics.instance.sendUnsentReports();
  } catch (_) {}
}

void _reportStartupFailureSync(Object error, StackTrace stackTrace) {
  if (!_crashlyticsAvailable || !_firebaseInitialized) return;
  try {
    unawaited(() async {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'zone',
        fatal: true,
      );
      await FirebaseCrashlytics.instance.sendUnsentReports();
    }());
  } catch (_) {}
}

bool get _crashlyticsAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> _bootstrap() async {
  await Hive.initFlutter();

  final mobileNative =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (!mobileNative) {
    appUsesFirebaseBackend = false;
    await configureDependencies(environment: 'mock');
    return;
  }

  try {
    await Firebase.initializeApp();
    appUsesFirebaseBackend = true;
    try {
      await configureFirebaseCrashReporting();
    } catch (e, st) {
      debugPrint('Crashlytics init skipped: $e\n$st');
    }
    await configureDependencies(environment: Environment.dev);
    try {
      await ensureGoogleSignInInitialized();
    } catch (e) {
      debugPrint('GoogleSignIn init: $e');
    }
  } catch (error, stackTrace) {
    appUsesFirebaseBackend = false;
    await _reportStartupFailure(error, stackTrace);
    try {
      await getIt.reset(dispose: true);
    } catch (_) {}
    await configureDependencies(environment: 'mock');
    scheduleStartupDemoFallbackNotice(error, stackTrace);
    assert(() {
      debugPrint(
        'eventa: не удалось подключить Firebase/Google (демо-режим). '
        'Причина: $error',
      );
      return true;
    }());
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.error,
    required this.stackTrace,
    super.key,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Startup error')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(
              'App failed to start.\n\n$error\n\n$stackTrace',
            ),
          ),
        ),
      ),
    );
  }
}
