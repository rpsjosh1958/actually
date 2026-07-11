import 'package:cloud_firestore/cloud_firestore.dart';

class MythFact {
  final String id;
  final String statement;
  final bool isTrue;
  final String why;
  final String? category;

  const MythFact({
    required this.id,
    required this.statement,
    required this.isTrue,
    required this.why,
    this.category,
  });

  factory MythFact.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MythFact(
      id: doc.id,
      statement: d['statement'] as String,
      isTrue: d['isTrue'] as bool,
      why: d['why'] as String,
      category: d['category'] as String?,
    );
  }
}
