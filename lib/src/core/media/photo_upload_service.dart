import 'dart:convert';

import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Загрузка фото из галереи: Storage при Firebase, иначе data-URL для локального режима.
class PhotoUploadService {
  PhotoUploadService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndUpload({
    required String ownerId,
    required String folder,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    if (appUsesFirebaseBackend && !kIsWeb) {
      try {
        final name =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
        final ref = FirebaseStorage.instance
            .ref()
            .child(folder)
            .child(ownerId)
            .child(name);
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        return await ref.getDownloadURL();
      } catch (_) {
        // Fallback ниже.
      }
    }

    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static ImageProvider? imageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      final raw = base64Decode(url.substring(comma + 1));
      return MemoryImage(Uint8List.fromList(raw));
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return null;
  }
}
