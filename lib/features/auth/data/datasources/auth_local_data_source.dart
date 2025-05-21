// import 'dart:convert';
// import 'package:korean_language_app/data/models/user_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // lib/data/datasources/auth_data_source.dart
// import 'package:firebase_auth/firebase_auth.dart';

// abstract class AuthDataSource {
//   Future<User> signInWithEmailAndPassword(String email, String password);
//   Future<User> signUpWithEmailAndPassword(String email, String password);
//   Future<void> signOut();
//   User? getCurrentUser();
//   Stream<User?> get userChanges;
// }

// class FirebaseAuthDataSource implements AuthDataSource {
//   final FirebaseAuth _firebaseAuth;
  
//   FirebaseAuthDataSource(this._firebaseAuth);
  
//   @override
//   Future<User> signInWithEmailAndPassword(String email, String password) async {
//     final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//     return userCredential.user!;
//   }
  
//   @override
//   Future<User> signUpWithEmailAndPassword(String email, String password) async {
//     final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//     return userCredential.user!;
//   }
  
//   @override
//   Future<void> signOut() async {
//     await _firebaseAuth.signOut();
//   }
  
//   @override
//   User? getCurrentUser() {
//     return _firebaseAuth.currentUser;
//   }
  
//   @override
//   Stream<User?> get userChanges => _firebaseAuth.authStateChanges();
// }