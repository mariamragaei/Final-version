import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  try {
    final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'drmohamed@gmail.com',
      password: '123456',
    );
    
    print('USER UID: ${userCred.user?.uid}');
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(userCred.user?.uid).get();
    
    if (doc.exists) {
      print('USER DOC DATA: ${doc.data()}');
    } else {
      print('USER DOC DOES NOT EXIST!');
    }
  } catch (e) {
    print('ERROR: $e');
  }
}
