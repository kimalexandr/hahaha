import 'dart:ui';

import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/core/media/photo_upload_service.dart';
import 'package:eventa/src/core/widgets/app_user_avatar.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/meetings/domain/dating_rules.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:eventa/src/features/profile/presentation/pages/premium_paywall_page.dart';
import 'package:eventa/src/features/profile/presentation/widgets/account_badges.dart';
import 'package:flutter/material.dart';

Future<void> openPublicProfile(
  BuildContext context, {
  String? userId,
  UserProfile? profile,
  String? fallbackName,
  String? fallbackPhotoUrl,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => PublicProfilePage(
            userId: userId ?? profile?.ownerId ?? '',
            initialProfile: profile,
            fallbackName: fallbackName,
            fallbackPhotoUrl: fallbackPhotoUrl,
          ),
    ),
  );
}

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({
    super.key,
    required this.userId,
    this.initialProfile,
    this.fallbackName,
    this.fallbackPhotoUrl,
  });

  final String userId;
  final UserProfile? initialProfile;
  final String? fallbackName;
  final String? fallbackPhotoUrl;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  UserProfile? _profile;
  UserProfile? _viewer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final persistence = ProfilePersistence();
    final viewer = await persistence.read(uid);
    UserProfile? profile = widget.initialProfile;
    if ((profile == null || profile.ownerId.isEmpty) &&
        widget.userId.isNotEmpty) {
      profile = await persistence.read(widget.userId);
    }
    profile ??= UserProfile(
      id: widget.userId,
      createdAt: DateTime.now(),
      ownerId: widget.userId,
      name: widget.fallbackName ?? 'Пользователь',
      bio: '',
      role: 'user',
      profilePhotoUrls:
          widget.fallbackPhotoUrl == null
              ? const []
              : [widget.fallbackPhotoUrl!],
    );
    if (!mounted) return;
    setState(() {
      _viewer = viewer;
      _profile = profile;
      _loading = false;
    });
  }

  bool get _canSeeClear {
    final viewer = _viewer;
    final profile = _profile;
    if (viewer == null || profile == null) return false;
    if (viewer.ownerId == profile.ownerId) return true;
    return viewer.hasActivePremium;
  }

  Future<void> _unlockForDemo() async {
    final bought = await openPremiumPaywall(
      context,
      reason: 'Полный просмотр анкет доступен с Premium.',
    );
    if (!bought || !mounted) return;
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final viewer = await ProfilePersistence().read(uid);
    if (!mounted) return;
    setState(() => _viewer = viewer);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = _profile!;
    final clear = _canSeeClear;
    final photo = PhotoUploadService.imageProvider(profile.mainPhotoUrl);
    final age =
        profile.birthDate == null ? null : calculateAge(profile.birthDate!);

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 220,
              height: 280,
              child:
                  photo == null
                      ? ColoredBox(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: AppUserAvatar(
                            name: profile.name,
                            radius: 48,
                          ),
                        ),
                      )
                      : Image(image: photo, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [
            if (age != null) '$age лет',
            if (profile.city.isNotEmpty) profile.city,
            if (profile.zodiacSign != null)
              zodiacRuLabel(profile.zodiacSign),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Center(child: AccountBadges(profile: profile)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('О себе', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  profile.bio.isEmpty ? 'Пока без описания' : profile.bio,
                ),
                const SizedBox(height: 12),
                Text('Интересы', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (profile.interests.isEmpty
                              ? const ['—']
                              : profile.interests)
                          .map((e) => Chip(label: Text(e)))
                          .toList(),
                ),
              ],
            ),
          ),
        ),
        if (profile.profilePhotoUrls.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profile.profilePhotoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final provider = PhotoUploadService.imageProvider(
                  profile.profilePhotoUrls[index],
                );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      provider == null
                          ? Container(
                            width: 96,
                            height: 96,
                            color: Colors.grey.shade300,
                          )
                          : Image(
                            image: provider,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                );
              },
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (clear)
            content
          else
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AbsorbPointer(child: content),
            ),
          if (!clear)
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Профиль доступен с платным доступом',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Сейчас виден размытый предпросмотр. Оформите платный профиль, чтобы открыть фото и детали.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _unlockForDemo,
                      child: const Text('Оформить Premium'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
