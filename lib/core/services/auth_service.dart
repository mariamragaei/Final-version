import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Firestore Error: $e');
      return null;
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final data = await getUserData(uid);
      if (data != null) {
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Firestore Error: $e');
      return null;
    }
  }

  Future<void> updateUserRole(String uid, {String? role, String? status}) async {
    try {
      Map<String, dynamic> updates = {};
      if (role != null) {
        updates['role'] = role;
        if (status == null) {
          updates['status'] = (role == 'doctor' || role == 'ta' || role == 'instructor') ? 'pending' : 'approved';
        }
      }
      if (status != null) {
        updates['status'] = status;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
      }
    } catch (e) {
      print('Firestore Update Error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail(String email, String password, {required String name, String? role, Map<String, dynamic>? additionalData}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        if (role != null) 'role': role,
        if (role != null) 'status': (role == 'doctor' || role == 'ta' || role == 'instructor') ? 'pending' : 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        if (additionalData != null) ...additionalData,
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Auth Error: ${e.code}');
      rethrow;
    }
  }

  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Auth Error: ${e.code}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
