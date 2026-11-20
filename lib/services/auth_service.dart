import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import 'demo_store.dart';

abstract class AuthService {
  Future<AppUser?> restoreSession();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> signOut();
}

class DemoAuthService implements AuthService {
  DemoAuthService(this._store);

  final DemoStore _store;

  @override
  Future<AppUser?> restoreSession() => _store.restoreSession();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) => _store.signIn(email, password);

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) => _store.register(
    name: name,
    email: email,
    password: password,
    role: role,
  );

  @override
  Future<void> signOut() => _store.signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<AppUser?> restoreSession() async {
    final current = _auth.currentUser;
    if (current == null) return null;
    try {
      return await _fetchProfile(current.uid);
    } catch (_) {
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AppException('Email atau password salah. Coba lagi ya.');
      }
      try {
        return await _fetchProfile(user.uid);
      } on AppException {
        await _auth.signOut();
        rethrow;
      }
    } on FirebaseAuthException catch (error) {
      throw AppException(_authMessage(error), code: error.code);
    }
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AppException('Registrasi gagal. Silakan coba lagi.');
      }
      await user.updateDisplayName(name.trim());
      final profile = AppUser(
        uid: user.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: role,
      );
      await _users.doc(user.uid).set(profile.toMap());
      return profile;
    } on FirebaseAuthException catch (error) {
      throw AppException(_authMessage(error), code: error.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _fetchProfile(String uid) async {
    final snapshot = await _users
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 15));
    if (!snapshot.exists) {
      throw AppException(
        'Dokumen users/$uid belum ada di Firestore dengan field role (admin/kasir).',
        code: 'profile-missing',
      );
    }
    return AppUser.fromMap(uid, snapshot.data()!);
  }

  String _authMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah. Coba lagi ya.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password minimal 6 karakter.';
      case 'network-request-failed':
        return 'Tidak ada koneksi. Periksa internet kamu lalu coba lagi.';
      case 'operation-not-allowed':
        return 'Provider Email/Password belum diaktifkan di Firebase Console.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      default:
        return error.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}
