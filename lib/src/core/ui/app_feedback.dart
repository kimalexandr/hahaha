import 'package:flutter/material.dart';

/// Короткий floating SnackBar с учётом системной панели; длинный текст — в диалоге.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  String? details,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final bottom = MediaQuery.paddingOf(context).bottom;
  final short =
      message.length > 120 ? '${message.substring(0, 117).trimRight()}…' : message;

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      duration: duration,
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      content: Text(short, maxLines: 3, overflow: TextOverflow.ellipsis),
      action:
          details != null && details.trim().isNotEmpty
              ? SnackBarAction(
                label: 'Ещё',
                textColor: isError ? Colors.white : null,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder:
                        (dialogContext) => AlertDialog(
                          title: const Text('Подробности'),
                          content: SingleChildScrollView(
                            child: SelectableText(details),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                },
              )
              : null,
    ),
  );
}
