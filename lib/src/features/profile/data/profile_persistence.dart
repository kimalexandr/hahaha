import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/features/home/data/local/home_local_storage.dart';
import 'package:eventa/src/features/home/data/remote/home_remote_storage.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

/// Сохраняет профиль локально и, если Firebase доступен, в Firestore.
class ProfilePersistence {
  ProfilePersistence({HomeLocalStorage? local, HomeRemoteStorage? remote})
    : _local = local ?? HomeLocalStorage(),
      _remote = remote;

  final HomeLocalStorage _local;
  final HomeRemoteStorage? _remote;

  /// [requireRemote]: при Firebase-бэкенде ошибка Firestore пробрасывается
  /// (нужно для критичных полей вроде places-quiz).
  Future<void> save(
    UserProfile profile, {
    bool requireRemote = false,
  }) async {
    final normalized = profile.copyWith(
      placesQuizAnswers: normalizePlacesQuizAnswers(profile.placesQuizAnswers),
    );
    await _local.saveProfile(normalized);
    if (!appUsesFirebaseBackend) return;
    final remote = _remote ?? HomeRemoteStorage();
    try {
      await remote.saveProfile(normalized);
    } catch (_) {
      if (requireRemote) rethrow;
      // Локальная копия уже сохранена.
    }
  }

  Future<UserProfile?> read(String ownerId) async {
    if (appUsesFirebaseBackend) {
      final remote = _remote ?? HomeRemoteStorage();
      try {
        final remoteProfile = await remote.readProfile(ownerId);
        if (remoteProfile != null) {
          final normalized = remoteProfile.copyWith(
            placesQuizAnswers: normalizePlacesQuizAnswers(
              remoteProfile.placesQuizAnswers,
            ),
          );
          await _local.saveProfile(normalized);
          return normalized;
        }
      } catch (_) {}
    }
    final local = await _local.readProfile();
    if (local == null) return null;
    final normalized = local.copyWith(
      placesQuizAnswers: normalizePlacesQuizAnswers(local.placesQuizAnswers),
    );
    if (local.ownerId == ownerId) return normalized;
    return normalized;
  }
}
