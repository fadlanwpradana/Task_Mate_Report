import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/user_directory.dart';
import '../../../l10n/app_localizations.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, UserDirectory? directory})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _directory = directory ?? UserDirectory();

  final FirebaseAuth _firebaseAuth;
  final UserDirectory _directory;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Keep the chat profile and email lookup in place for older accounts.
    if (credential.user case final user?) await _saveProfile(user);
    return credential;
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(fullName.trim());
      await _saveProfile(user, name: fullName);
    }
    return credential;
  }

  /// Changes the account's display name everywhere others can see it.
  Future<void> updateName(String name) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await _saveProfile(user, name: name);
  }

  Future<void> _saveProfile(User user, {String? name}) async {
    try {
      await _directory.saveProfile(user, name: name);
    } catch (error) {
      // Sign-in still works; the profile is saved again next time.
      debugPrint('Could not save the user profile: $error');
    }
  }

  static bool _googleReady = false;

  /// Signs in (or registers, the first time) with a Google account.
  /// Returns null if the user closes the account picker.
  ///
  /// Throws [GoogleSignInException] or [FirebaseAuthException] on failure.
  Future<UserCredential?> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      // On Android the web client id comes from google-services.json.
      await google.initialize();
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final credential = await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: account.authentication.idToken),
    );
    if (credential.user case final user?) await _saveProfile(user);
    return credential;
  }

  Future<void> sendPasswordReset(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (_googleReady) {
      // So the account picker shows again next time.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (error) {
        debugPrint('Google sign-out failed: $error');
      }
    }
    await _firebaseAuth.signOut();
  }

  static String messageFor(FirebaseAuthException error, AppLocalizations l10n) {
    return switch (error.code) {
      'invalid-email' => l10n.invalidEmail,
      'user-disabled' => l10n.authUserDisabled,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => l10n.authWrongCredentials,
      'email-already-in-use' => l10n.authEmailInUse,
      'weak-password' => l10n.authWeakPassword,
      'too-many-requests' => l10n.authTooManyRequests,
      'network-request-failed' => l10n.authNetwork,
      'operation-not-allowed' => l10n.authNotEnabled,
      'account-exists-with-different-credential' => l10n.authAccountExists,
      _ => error.message ?? l10n.authFailed,
    };
  }
}
