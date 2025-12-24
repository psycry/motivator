import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  bool _googleSignInInitAttempted = false;
  bool _googleSignInAvailable = false;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously (for quick setup)
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create or update user profile in Firestore
    if (credential.user != null) {
      await _userService.createOrUpdateUser(credential.user!, 'email');
    }
    
    return credential;
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create user profile in Firestore
    if (credential.user != null) {
      await _userService.createOrUpdateUser(credential.user!, 'email');
    }
    
    return credential;
  }

  // Check if Google Sign-In is available
  bool get isGoogleSignInAvailable {
    if (_googleSignInInitAttempted) return _googleSignInAvailable;
    
    _googleSignInInitAttempted = true;
    try {
      _googleSignIn = GoogleSignIn();
      _googleSignInAvailable = true;
      print('✓ Google Sign-In initialized successfully');
    } catch (e) {
      print('⚠️ Google Sign-In initialization failed: $e');
      print('⚠️ Google Sign-In will be disabled. Email/password auth still works.');
      _googleSignIn = null;
      _googleSignInAvailable = false;
    }
    return _googleSignInAvailable;
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw Exception('Google Sign-In is not configured. Please set up the Client ID.');
    }
    
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        throw Exception('Google sign-in was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Create or update user profile in Firestore
      if (userCredential.user != null) {
        await _userService.createOrUpdateUser(userCredential.user!, 'google');
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    final futures = <Future>[_auth.signOut()];
    if (_googleSignIn != null) {
      futures.add(_googleSignIn!.signOut());
    }
    await Future.wait(futures);
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
