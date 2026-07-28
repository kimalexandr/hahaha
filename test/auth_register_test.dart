import 'dart:io';

import 'package:eventa/src/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDir;
  late MockAuthRepository auth;

  setUp(() async {
    hiveDir = Directory.systemTemp.createTempSync('eventa_auth_test');
    Hive.init(hiveDir.path);
    auth = MockAuthRepository();
  });

  tearDown(() async {
    await auth.signOut();
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  test('register creates account and authenticates', () async {
    await auth.registerWithEmailAndPassword('new@eventa.app', 'secret1');
    expect(await auth.authStateChanges.first, isTrue);
  });

  test('register rejects duplicate email', () async {
    await auth.registerWithEmailAndPassword('dup@eventa.app', 'secret1');
    await auth.signOut();
    await expectLater(
      auth.registerWithEmailAndPassword('dup@eventa.app', 'secret2'),
      throwsA(isA<Exception>()),
    );
  });

  test('sign in works after register', () async {
    await auth.registerWithEmailAndPassword('login@eventa.app', 'secret1');
    await auth.signOut();
    await auth.signInWithEmailAndPassword('login@eventa.app', 'secret1');
    expect(await auth.authStateChanges.first, isTrue);
  });

  test('register rejects short password', () async {
    await expectLater(
      auth.registerWithEmailAndPassword('short@eventa.app', '123'),
      throwsA(isA<Exception>()),
    );
  });
}
