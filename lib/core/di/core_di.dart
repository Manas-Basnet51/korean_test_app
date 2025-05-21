// lib/core/di/feature_di/core_di.dart
import 'package:get_it/get_it.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/core/presentation/theme/bloc/theme_cubit.dart';
import 'package:korean_language_app/core/presentation/connectivity/bloc/connectivity_cubit.dart';

void registerCoreDependencies(GetIt sl) {
  // Core utilities
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(connectivity: sl()));
  
  // App-wide Cubits
  sl.registerLazySingleton(() => LanguagePreferenceCubit(prefs: sl()));
  sl.registerLazySingleton(() => ThemeCubit(sl()));
  sl.registerLazySingleton<SnackBarCubit>(() => SnackBarCubit(languageCubit: sl()));
  sl.registerLazySingleton(() => ConnectivityCubit(networkInfo: sl()));
}