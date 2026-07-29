import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/push/data/push_notification_service.dart';
import 'package:injectable/injectable.dart';

import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<bool>? _authStateSubscription;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);

    on<_AuthStatusChanged>((event, emit) {
      if (event.isAuthenticated) {
        emit(Authenticated());
      } else {
        emit(Unauthenticated());
      }
    });

    on<AuthSignOutRequested>((event, emit) async {
      try {
        await pushNotificationService.stopAndClearToken();
      } catch (_) {}
      await _authRepository.signOut();
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _authStateSubscription?.cancel();

    // Сразу синхронизируем состояние (важно после Google Sign-In).
    try {
      final uid = await _authRepository.currentUserId();
      emit(uid != null ? Authenticated() : Unauthenticated());
    } catch (_) {
      emit(Unauthenticated());
    }

    _authStateSubscription = _authRepository.authStateChanges.listen(
      (isAuthenticated) {
        add(_AuthStatusChanged(isAuthenticated));
      },
      onError: (Object error, StackTrace stackTrace) {
        addError(error, stackTrace);
        add(const _AuthStatusChanged(false));
      },
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

class _AuthStatusChanged extends AuthEvent {
  final bool isAuthenticated;

  const _AuthStatusChanged(this.isAuthenticated);

  @override
  List<Object> get props => [isAuthenticated];
}
