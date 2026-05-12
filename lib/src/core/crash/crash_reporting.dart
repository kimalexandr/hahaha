import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Подключает отправку ошибок Flutter в Firebase Crashlytics (консоль Firebase).
/// Вызывать только после [Firebase.initializeApp] на поддерживаемых платформах.
Future<void> configureFirebaseCrashReporting() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    unawaited(_flushFlutterFatal(details));
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    unawaited(_flushPlatformError(error, stack));
    return true;
  };

  await FirebaseCrashlytics.instance.setCustomKey('kDebugMode', kDebugMode);
  FirebaseCrashlytics.instance.log('crashlytics_initialized');
  // Досылает очередь с прошлых сессий и помогает «пробить» пустой дашборд после онбординга.
  await FirebaseCrashlytics.instance.sendUnsentReports();
}

Future<void> _flushFlutterFatal(FlutterErrorDetails details) async {
  await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  await FirebaseCrashlytics.instance.sendUnsentReports();
}

Future<void> _flushPlatformError(Object error, StackTrace stack) async {
  await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  await FirebaseCrashlytics.instance.sendUnsentReports();
}
