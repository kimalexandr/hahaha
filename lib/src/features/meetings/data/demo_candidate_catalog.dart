import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:eventa/src/features/profile/domain/profile_interest_catalog.dart';

/// Демо-кандидаты для подбора компании (пока без реальных пользователей).
class DemoCandidateCatalog {
  DemoCandidateCatalog._();

  static List<UserProfile> all({required String excludeOwnerId}) {
    final now = DateTime.now();
    final all = [
      UserProfile(
        id: 'cand-1',
        createdAt: now,
        ownerId: 'cand-1',
        name: 'Мария',
        bio: 'Люблю кофе и вечерние прогулки',
        role: 'user',
        city: 'Almaty',
        interests: const ['Кофе', 'Прогулки', 'Кино'],
        readyForMeeting: true,
      ),
      UserProfile(
        id: 'cand-2',
        createdAt: now,
        ownerId: 'cand-2',
        name: 'Данияр',
        bio: 'Спорт и хорошая еда',
        role: 'user',
        city: 'Almaty',
        interests: const ['Спорт', 'Еда', 'Музыка'],
        readyForMeeting: true,
      ),
      UserProfile(
        id: 'cand-3',
        createdAt: now,
        ownerId: 'cand-3',
        name: 'Алина',
        bio: 'Книги, искусство, тихие места',
        role: 'user',
        city: 'Almaty',
        interests: const ['Книги', 'Искусство', 'Кофе'],
        readyForMeeting: true,
      ),
      UserProfile(
        id: 'cand-4',
        createdAt: now,
        ownerId: 'cand-4',
        name: 'Тимур',
        bio: 'Технологии и настолки',
        role: 'user',
        city: 'Astana',
        interests: const ['Технологии', 'Игры', 'Кофе'],
        readyForMeeting: true,
      ),
      UserProfile(
        id: 'cand-5',
        createdAt: now,
        ownerId: 'cand-5',
        name: 'Сара',
        bio: 'Танцы и живая музыка',
        role: 'user',
        city: 'Astana',
        interests: ProfileInterestCatalog.all.take(4).toList(),
        readyForMeeting: true,
      ),
    ];
    return all.where((p) => p.ownerId != excludeOwnerId).toList();
  }
}
