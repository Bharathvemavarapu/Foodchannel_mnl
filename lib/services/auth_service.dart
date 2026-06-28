import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static const String dbUrl = "https://foodchannelmnl-default-rtdb.firebaseio.com";

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Retrieves user profile details (including role) from RTDB
  static Future<UserModel?> getUserProfile(String uid) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) return null;

    final response = await http.get(Uri.parse('$dbUrl/users/$uid.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return null;
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return UserModel.fromJson(uid, data);
  }

  /// Sign In and retrieve User Profile
  static Future<UserModel> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception("User is null after sign in.");

    final profile = await getUserProfile(user.uid);
    if (profile == null) {
      final defaultProfile = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: email,
        role: 'user',
        createdDate: DateTime.now(),
        lastLogin: DateTime.now(),
        isActive: true,
        phone: '',
      );
      await saveUserProfile(defaultProfile);
      return defaultProfile;
    } else {
      final updatedProfile = profile.copyWith(lastLogin: DateTime.now());
      await saveUserProfile(updatedProfile);
      return updatedProfile;
    }
  }

  /// Register new user and save user role in Realtime Database
  static Future<void> register(String email, String password, String name, String role) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception("Registration failed.");

    await user.updateDisplayName(name);
    await user.sendEmailVerification();

    final profile = UserModel(
      uid: user.uid,
      name: name,
      email: email.trim(),
      role: role,
      createdDate: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
      phone: '',
    );

    await saveUserProfile(profile);
  }

  /// Saves user profile directly to Realtime Database
  static Future<void> saveUserProfile(UserModel profile) async {
    final token = await _auth.currentUser?.getIdToken();
    final url = Uri.parse('$dbUrl/users/${profile.uid}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(profile.toJson()));
    if (response.statusCode != 200) {
      throw Exception("Failed to save user role profile data.");
    }
  }

  /// Sends password reset email
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Logs out current user
  static Future<void> logout() async {
    await _auth.signOut();
  }
}
