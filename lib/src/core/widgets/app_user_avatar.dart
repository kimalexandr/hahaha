import 'package:eventa/src/core/media/photo_upload_service.dart';
import 'package:flutter/material.dart';

class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.radius = 20,
    this.onTap,
  });

  final String? photoUrl;
  final String? name;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final provider = PhotoUploadService.imageProvider(photoUrl);
    final trimmed = name?.trim() ?? '';
    final initial =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage: provider,
      child: provider == null ? Text(initial) : null,
    );
    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}
