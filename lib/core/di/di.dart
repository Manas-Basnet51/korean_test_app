import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:korean_language_app/core/di/admin_di.dart';
import 'package:korean_language_app/core/di/auth_di.dart';
import 'package:korean_language_app/core/di/books_di.dart';
import 'package:korean_language_app/core/di/core_di.dart';
import 'package:korean_language_app/core/di/profile_di.dart';
import 'package:korean_language_app/core/di/test_results_di.dart';
import 'package:korean_language_app/core/di/tests_di.dart';
import 'package:korean_language_app/core/di/test_upload_di.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External services & packages
  await _registerExternalDependencies();
  
  //! Core utilities and services
  registerCoreDependencies(sl);
  
  //! Feature-specific dependencies
  registerAuthDependencies(sl);
  registerProfileDependencies(sl);
  registerBooksDependencies(sl);
  registerAdminDependencies(sl);
  registerTestsDependencies(sl);
  registerTestUploadDependencies(sl);
  registerTestResultsDependencies(sl);
}
   
Future<void> _registerExternalDependencies() async {
  // Shared third-party services
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Network related
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton(() => Connectivity());
  
  // Firebase services
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
}