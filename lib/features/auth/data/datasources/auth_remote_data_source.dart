import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthDataSource {
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> signUpWithEmailAndPassword(String email, String password);

  Future<UserCredential> signInAnonymously();
  Future<User> signInWithGoogle(); 

  Future<void> signOut();
  Future<void> resetPassword(String email);
  User? getCurrentUser();
  Stream<User?> get userChanges;
}


//Implementation

class FirebaseAuthDataSource implements AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  FirebaseAuthDataSource(this._firebaseAuth,this._googleSignIn);
  
  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user!;
  }
  
  @override
  Future<User> signUpWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user!;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    return await _firebaseAuth.signInAnonymously();
  }

  @override
  Future<User> signInWithGoogle() async {
    // Trigger the Google Sign-In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    // If the user canceled the sign-in flow, return null
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
    
    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // Sign in to Firebase with the Google credential
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user!;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
  
  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
  
  @override
  Stream<User?> get userChanges => _firebaseAuth.authStateChanges();
}