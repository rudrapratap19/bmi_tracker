import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../models/weight_entry.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveProfile(String uid, UserProfile profile) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<List<UserProfile>> getProfiles(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data()))
            .toList());
  }

  Future<void> addWeightEntry(String uid, String profileId, WeightEntry entry) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .collection('weights')
        .add(entry.toMap());
  }

  Future<void> addWeightEntryWithId(
    String uid,
    String profileId,
    String entryId,
    WeightEntry entry,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .collection('weights')
        .doc(entryId)
        .set(entry.toMap());
  }

  Stream<List<WeightEntry>> getWeightHistory(String uid, String profileId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .collection('weights')
        .orderBy('date', descending: true)
        .limit(7)
        .snapshots()
        .map((s) => s.docs.map((d) => WeightEntry.fromFirestore(d.id, d.data())).toList());
  }

  Future<List<WeightEntry>> getWeightHistoryOnce(String uid, String profileId) async {
    final s = await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .collection('weights')
        .orderBy('date', descending: true)
        .limit(7)
        .get();
    return s.docs.map((d) => WeightEntry.fromFirestore(d.id, d.data())).toList();
  }

  Future<UserProfile?> getProfile(String uid, String profileId) async {
    final d = await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .get();
    if (!d.exists) return null;
    return UserProfile.fromMap(d.data()!);
  }

  Future<void> restoreProfileWithWeights(
    String uid,
    UserProfile profile,
    List<WeightEntry> entries,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));

    final batch = _db.batch();
    for (final e in entries) {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('profiles')
          .doc(profile.id)
          .collection('weights')
          .doc(e.id ?? _db.collection('_').doc().id);
      batch.set(ref, e.toMap());
    }
    await batch.commit();
  }

  Future<bool> profileExists(String uid, String profileId) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .get();
    return doc.exists;
  }

  Future<void> deleteWeightEntry(String uid, String profileId, String entryId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .collection('weights')
        .doc(entryId)
        .delete();
  }

  Future<void> deleteProfile(String uid, String profileId) async {
    // Delete weights subcollection documents
    final weights = await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .collection('weights')
        .get();
    for (final w in weights.docs) {
      await w.reference.delete();
    }
    // Delete profile document
    await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .delete();
  }
}
