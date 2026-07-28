import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/features/home/data/local/home_local_storage.dart';
import 'package:eventa/src/features/home/data/remote/home_remote_storage.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

/// Сохраняет профиль локально и, если Firebase доступен, в Firestore.
class ProfilePersistence {
  ProfilePersistence({
    HomeLocalStorage? local,
    HomeRemoteStorage? remote,
  }) : _local = local ?? HomeLocalStorage(),
       _remote = remote;

  final HomeLocalStorage _local;
  final HomeRemoteStorage? _remote;

  Future<void> save(UserProfile profile) async {
    await _local.saveProfile(profile);
    if (!appUsesFirebaseBackend) return;
    final remote = _remote ?? HomeRemoteStorage();
    try {
      await remote.saveProfile(profile);
    } catch (_) {
      // Локальная копия уже сохранена.
    }
  }

  Future<UserProfile?> read(String ownerId) async {
    if (appUsesFirebaseBackend) {
      final remote = _remote ?? HomeRemoteStorage();
      try {
        final remoteProfile = await remote.readProfile(ownerId);
        if (remoteProfile != null) {
          await _local.saveProfile(remoteProfile);
          return remoteProfile;
        }
      } catch (_) {}
    }
    final local = await _local.readProfile();
    if (local != null && local.ownerId == ownerId) return local;
    return local;
  }
}
