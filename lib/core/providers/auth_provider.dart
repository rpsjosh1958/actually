import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Same Firebase project as SORTA-APP (sorta-3df17) — this is the shared
/// identity layer, not Actually-specific. Kept identical to SORTA's
/// auth_provider.dart so both apps observe the same Auth session shape.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});
