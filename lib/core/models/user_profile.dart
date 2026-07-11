import 'package:cloud_firestore/cloud_firestore.dart';

/// Trimmed view of SORTA's `users/{uid}` doc — only the identity fields
/// Actually needs (displayName, avatarSeed). Never write gameplay fields
/// onto this doc; that's what `actuallyProfiles/{uid}` is for.
class UserProfile {
  final String uid;
  final String displayName;
  final String avatarSeed;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.avatarSeed,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? 'Player',
      avatarSeed: d['avatarSeed'] as String? ?? doc.id,
    );
  }
}
