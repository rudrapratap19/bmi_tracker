import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveProfile(String uid, UserProfile profile) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profile.id)
        .set(profile.toMap());
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
}
