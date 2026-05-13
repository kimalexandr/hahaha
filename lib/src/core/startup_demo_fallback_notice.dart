/// Одноразовое сообщение: приложение перешло в демо из-за сбоя подключения Firebase/Google.
String? _pendingDemoFallbackNotice;

void scheduleStartupDemoFallbackNotice(Object error, StackTrace stackTrace) {
  final sb =
      StringBuffer()
        ..writeln(error.toString())
        ..writeln()
        ..writeln(stackTrace.toString());
  _pendingDemoFallbackNotice = sb.toString();
}

/// Снимает и возвращает текст для показа пользователю (один раз).
String? takeStartupDemoFallbackNoticeIfAny() {
  final m = _pendingDemoFallbackNotice;
  _pendingDemoFallbackNotice = null;
  return m;
}
