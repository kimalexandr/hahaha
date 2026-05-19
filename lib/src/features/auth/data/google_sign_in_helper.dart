import 'package:eventa/src/core/constants/google_oauth_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool _googleSignInInitialized = false;

Future<void> ensureGoogleSignInInitialized() async {
  if (_googleSignInInitialized) return;
  await GoogleSignIn.instance.initialize(
    serverClientId: kGoogleSignInWebClientId,
  );
  _googleSignInInitialized = true;
}

/// Сообщение для пользователя при типичных сбоях Google Sign-In на Android.
String googleSignInUserMessage(Object error) {
  final text = error.toString();
  if (error is GoogleSignInException) {
    if (text.contains('reauth') ||
        text.contains('[16]') ||
        text.contains('Account reauth failed')) {
      return 'Не удалось войти через Google: неверная настройка приложения в '
          'Firebase (чаще всего SHA-1 ключа подписи). '
          'В консоли Firebase → проект eventus-f450f → настройки Android-приложения '
          'добавьте отпечаток SHA-1 и SHA-256 для debug и release, '
          'скачайте новый google-services.json, пересоберите и установите APK заново.';
    }
    if (error.code.toString().contains('canceled') &&
        !text.contains('reauth') &&
        !text.contains('[16]')) {
      return 'Вход через Google отменён.';
    }
  }
  return 'Ошибка входа через Google: $text';
}
