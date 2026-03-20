// lib/services/auth_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // login
  static Future<User?> login(String email, String password) async {
    final cred = await auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  // register customer
  static Future<User?> registerCustomer(String name, String email, String password) async {
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    await db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred.user;
  }

  // get user document (role + extras)
  static Future<DocumentSnapshot<Map<String, dynamic>>?> getUserDoc(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc;
  }

  // Admin: create store account (creates Firebase Auth user + store doc + user doc)
  static Future<void> createStoreAccount({
    required String storeName,
    required String email,
    required String password,
    required String location,
    required String phone,
    File? logoFile,
  }) async {
    // create auth user (admin must be logged in and call this)
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;

    // upload logo if provided
    String? logoUrl;
    if (logoFile != null) {
      final String fileId = const Uuid().v4();
      final ref = storage.ref('store_logos/$fileId.png');
      await ref.putFile(logoFile);
      logoUrl = await ref.getDownloadURL();
    }

    // create store doc
    final storeRef = db.collection('stores').doc();
    final storeId = storeRef.id;
    await storeRef.set({
      'name': storeName,
      'location': location,
      'logoUrl': logoUrl,
      'phone': phone,
      'ownerUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // create user doc with role=store and link to storeId
    await db.collection('users').doc(uid).set({
      'uid': uid,
      'name': storeName,
      'role': 'store',
      'storeId': storeId,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin: create driver account
  static Future<void> createDriverAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String vehiclePlate,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;

    // create driver doc
    final driverRef = db.collection('drivers').doc();
    final driverId = driverRef.id;
    await driverRef.set({
      'name': name,
      'phone': phone,
      'vehiclePlate': vehiclePlate,
      'ownerUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'role': 'driver',
      'driverId': driverId,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}