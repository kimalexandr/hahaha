// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/repositories/firebase_auth_repository.dart'
    as _i900;
import '../../features/auth/data/repositories/mock_auth_repository.dart'
    as _i703;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;

const String _mock = 'mock';
const String _dev = 'dev';

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  gh.lazySingleton<_i787.AuthRepository>(
    () => _i703.MockAuthRepository(),
    registerFor: {_mock},
  );
  gh.lazySingleton<_i787.AuthRepository>(
    () => _i900.FirebaseAuthRepository(),
    registerFor: {_dev},
  );
  gh.factory<_i797.AuthBloc>(() => _i797.AuthBloc(gh<_i787.AuthRepository>()));
  return getIt;
}
