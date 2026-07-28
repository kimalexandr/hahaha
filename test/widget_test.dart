// Basic widget smoke test: реальное приложение с mock-окружением DI.

import 'dart:io';

import 'package:eventa/src/app/app.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDir = Directory.systemTemp.createTempSync('eventa_widget_test');
    Hive.init(hiveDir.path);
    await configureDependencies(environment: 'mock');
  });

  tearDownAll(() async {
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  testWidgets('приложение строится и показывает экран входа', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Eventa'), findsOneWidget);
    expect(find.text('Войти через Google'), findsOneWidget);
    expect(find.text('Создать аккаунт'), findsOneWidget);
  });
}
