import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<bool>? _authStateSubscription;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) {
      _authStateSubscription?.cancel();
      _authStateSubscription = _authRepository.authStateChanges.listen(
        (isAuthenticated) {
          add(_AuthStatusChanged(isAuthenticated));
        },
        onError: (Object error, StackTrace stackTrace) {
          addError(error, stackTrace);
          add(const _AuthStatusChanged(false));
        },
      );
    });

    on<_AuthStatusChanged>((event, emit) {
      if (event.isAuthenticated) {
        emit(Authenticated());
      } else {
        emit(Unauthenticated());
      }
    });

    on<AuthSignOutRequested>((event, emit) async {
      await _authRepository.signOut();
    });
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

// Private event for internal use
class _AuthStatusChanged extends AuthEvent {
  final bool isAuthenticated;

  const _AuthStatusChanged(this.isAuthenticated);

  @override
  List<Object> get props => [isAuthenticated];
}
