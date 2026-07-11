import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/actually_profile_provider.dart';

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) =>
      AuthState(isLoading: isLoading ?? this.isLoading, error: error);
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

/// Same identity contract as SORTA-APP's auth_view_model.dart — same
/// `usernames`/`users` collections in the shared sorta-3df17 project, so an
/// account created in either app works in both. This app never writes
/// gameplay fields onto `users/{uid}`.
class AuthViewModel extends Notifier<AuthState> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  AuthState build() => const AuthState();

  Future<void> signInWithEmailOrUsername(
    String emailOrUsername,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String email = emailOrUsername.trim();

      if (!email.contains('@')) {
        final doc = await _db
            .collection('usernames')
            .doc(email.toLowerCase())
            .get();
        if (!doc.exists) {
          state = state.copyWith(
            isLoading: false,
            error: 'No account found with that username.',
          );
          return;
        }
        final stored = doc.data()?['email'] as String?;
        if (stored == null || stored.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Please sign in with your email instead.',
          );
          return;
        }
        email = stored;
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await ref.read(actuallyProfileActionsProvider).bootstrapIfNeeded();
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e.code));
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      final name = username.trim().isNotEmpty ? username.trim() : 'Player';

      await user.updateDisplayName(name);

      final taken = await _db
          .collection('usernames')
          .doc(name.toLowerCase())
          .get();
      if (taken.exists && taken.data()?['uid'] != user.uid) {
        await user.delete();
        state = state.copyWith(
          isLoading: false,
          error: 'Username already taken.',
        );
        return;
      }

      await _db.collection('usernames').doc(name.toLowerCase()).set({
        'uid': user.uid,
        'email': user.email ?? '',
      });

      // Minimal identity bootstrap only — SORTA's UserProfile.fromDoc defaults
      // any of its own gameplay fields to 0 when absent, so this stays
      // compatible without Actually ever writing SORTA-specific fields.
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': name,
        'avatarSeed': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await ref.read(actuallyProfileActionsProvider).bootstrapIfNeeded();

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e.code));
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Account created but profile setup failed. Please try signing in.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void clearError() => state = state.copyWith(error: null);

  String _message(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
