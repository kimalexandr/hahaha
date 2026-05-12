import 'dart:async';

import 'package:eventa/src/app/app.dart';
import 'package:eventa/src/core/crash/crash_reporting.dart';
import 'package:eventa/src/core/di/injection.dart';
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

Future<void> _reportStartupFailure(Object error, StackTrace stackTrace) async {
  if (!_crashlyticsAvailable) return;
  try {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'bootstrap',
      fatal: true,
    );
  } catch (_) {}
}

void _reportStartupFailureSync(Object error, StackTrace stackTrace) {
  if (!_crashlyticsAvailable) return;
  try {
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'zone',
        fatal: true,
      ),
    );
  } catch (_) {}
}

bool get _crashlyticsAvailable =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> _bootstrap() async {
  await Hive.initFlutter();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await Firebase.initializeApp();
    await configureFirebaseCrashReporting();
  }
  await configureDependencies(
    environment:
        (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS))
            ? Environment.dev
            : 'mock',
  );
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
