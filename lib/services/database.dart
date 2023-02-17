import 'package:allokate/model/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:allokate/utils/list_utils.dart';

class DatabaseService {
  static Future<List<String>> getHeldInSuggestions(String pattern) {
    return FirebaseFirestore.instance
        .collection(fundsCollection)
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser.uid)
        .where('heldIn', isGreaterThanOrEqualTo: pattern)
        .get()
        .then((result) => result.docs.map<String>((e) => e.get('heldIn')).toSet().toList().order((a, b) =>
            StringSimilarity.compareTwoStrings(b, pattern).compareTo(StringSimilarity.compareTwoStrings(a, pattern))));
  }

  Future<void> updateMessagingToken(String token) async {
    User currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || token == null) return;
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({'messagingToken': token}, SetOptions(merge: true));
  }

  static Future<bool> get usersDocumentExistsInDatabase async {
    DocumentSnapshot usersDocument =
        await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser.uid).get();
    return usersDocument.exists;
  }
}
