import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'error_reporter.dart';

/// Wraps Firebase email/password auth — the app now requires a signed-in
/// user before showing any content (see [AuthGate] in main.dart).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    }
  }

  Future<String?> signUp({required String email, required String password, required String displayName}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.sendEmailVerification();
      // updateDisplayName doesn't refresh the cached currentUser synchronously
      // on every platform — reload so authStateChanges/currentUser reflect it.
      await cred.user?.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Re-sends the verification e-mail — fails soft (no error surfaced to
  /// the caller) since Firebase rate-limits this and the banner's own retry
  /// affordance is enough of a UX signal without a hard error state.
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e, st) {
      ErrorReporter.report('AuthService.sendEmailVerification', e, st);
    }
  }

  /// Reloads the current user from Firebase and returns the fresh
  /// `emailVerified` flag — `authStateChanges` doesn't fire when only the
  /// verification status changes, so callers must poll this explicitly
  /// (e.g. a "I've verified" button).
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
    } catch (e, st) {
      ErrorReporter.report('AuthService.refreshEmailVerified', e, st);
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Sends Firebase's built-in reset-password e-mail. Returns null on
  /// success (Firebase doesn't reveal whether the address is registered, to
  /// avoid leaking account existence).
  Future<String?> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    }
  }

  /// Permanently deletes the signed-in user's account and its Firestore
  /// data. Firebase requires a *recent* sign-in for this sensitive
  /// operation, so [password] re-authenticates first — a stale session
  /// would otherwise fail with `requires-recent-login`.
  Future<String?> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return "Aucun compte connecté.";
    try {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: password));
      await _deleteFirestoreData(user.uid);
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    }
  }

  /// Best-effort cleanup — account deletion still proceeds even if some of
  /// this fails (e.g. offline), since orphaned docs are harmless once keyed
  /// by a uid that can no longer authenticate.
  Future<void> _deleteFirestoreData(String uid) async {
    final db = FirebaseFirestore.instance;
    try {
      final userDoc = db.collection('users').doc(uid);
      await userDoc.collection('progress').doc('data').delete();
      final friends = await userDoc.collection('friends').get();
      for (final doc in friends.docs) {
        await doc.reference.delete();
      }
      await userDoc.delete();
    } catch (e, st) {
      ErrorReporter.report('AuthService._deleteFirestoreData', e, st);
    }
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Adresse e-mail invalide.";
      case 'user-disabled':
        return "Ce compte a été désactivé.";
      case 'user-not-found':
        return "Aucun compte n'existe avec cette adresse.";
      case 'wrong-password':
      case 'invalid-credential':
        return "E-mail ou mot de passe incorrect.";
      case 'email-already-in-use':
        return "Un compte existe déjà avec cette adresse.";
      case 'weak-password':
        return "Mot de passe trop faible (6 caractères minimum).";
      case 'network-request-failed':
        return "Connexion impossible — vérifie ta connexion internet.";
      case 'requires-recent-login':
        return "Reconnecte-toi puis réessaie — cette action nécessite une connexion récente.";
      case 'too-many-requests':
        return "Trop de tentatives — réessaie dans quelques minutes.";
      default:
        return e.message ?? "Une erreur est survenue. Réessaie.";
    }
  }
}
