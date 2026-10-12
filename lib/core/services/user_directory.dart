import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_model.dart';

/// Public user profiles in Firestore.
///
/// `users/{uid}` holds only a display name. `emailIndex/{email}` maps an
/// exact, lowercased email to a user and can only be read by document id,
/// so nobody can list users; you need someone's full email to find them.
class UserDirectory {
  UserDirectory([FirebaseFirestore? firestore]) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Name to show for [user]: display name, else the part before "@".
  static String nameFor(User user, [String? override]) {
    final name = (override ?? user.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    return (user.email ?? '').split('@').first;
  }

  /// Creates or refreshes [user]'s profile and email lookup.
  Future<void> saveProfile(User user, {String? name}) async {
    final email = user.email;
    if (email == null) return;
    final displayName = nameFor(user, name);
    final batch = _db.batch()
      ..set(_db.collection('users').doc(user.uid), {
        'name': displayName,
      }, SetOptions(merge: true))
      ..set(_db.collection('emailIndex').doc(email.toLowerCase()), {
        'uid': user.uid,
        'name': displayName,
      });
    await batch.commit();
  }

  /// The user registered with exactly [email], or null.
  Future<ChatUser?> lookup(String email) async {
    final key = email.trim().toLowerCase();
    if (key.isEmpty || key.contains('/')) return null;
    final doc = await _db.collection('emailIndex').doc(key).get();
    final data = doc.data();
    if (data == null) return null;
    return ChatUser(
      id: data['uid'] as String,
      name: data['name'] as String? ?? key,
      email: key,
    );
  }

  Future<String?> nameOf(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['name'] as String?;
  }
}
