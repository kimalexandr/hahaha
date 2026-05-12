import 'dart:async';

import 'package:eventa/src/app/app.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:firebase_core/firebase_core.dart';
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
        runApp(StartupErrorApp(error: error, stackTrace: stackTrace));
      }
    },
    (error, stackTrace) {
      runApp(StartupErrorApp(error: error, stackTrace: stackTrace));
    },
  );
}

Future<void> _bootstrap() async {
  await Hive.initFlutter();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await Firebase.initializeApp();
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
