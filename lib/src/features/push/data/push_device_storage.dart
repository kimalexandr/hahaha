import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventa/src/features/push/domain/notification_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Хранит FCM-токены в `users/{uid}/devices/{deviceId}` и настройки пушей.
class PushDeviceStorage {
  PushDeviceStorage({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _deviceBox = 'eventa_push_device';
  static const _deviceIdKey = 'deviceId';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _devices(String uid) =>
      _firestore.collection('users').doc(uid).collection('devices');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<String> stableDeviceId() async {
    final box =
        Hive.isBoxOpen(_deviceBox)
            ? Hive.box(_deviceBox)
            : await Hive.openBox(_deviceBox);
    final existing = box.get(_deviceIdKey) as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    final id =
        'dev-${DateTime.now().millisecondsSinceEpoch}-'
        '${DateTime.now().microsecondsSinceEpoch % 100000}';
    await box.put(_deviceIdKey, id);
    return id;
  }

  Future<void> upsertToken({
    required String uid,
    required String token,
  }) async {
    final deviceId = await stableDeviceId();
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

    final userRef = _userDoc(uid);
    await userRef.set({
      'notificationSettings': const NotificationSettings().toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _devices(uid).doc(deviceId).set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeCurrentDevice(String uid) async {
    final deviceId = await stableDeviceId();
    await _devices(uid).doc(deviceId).delete();
  }
}
