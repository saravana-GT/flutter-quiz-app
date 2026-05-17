import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_platform/models/user.dart';
import 'package:quiz_platform/repositories/mock_data.dart';

class AuthRepository {
  static const String _userKey = 'current_user';

  Future<User?> login(String email, String password) async {
    // In a real app, you would make an API call here.
    // For the demo, we check against MockData and a dummy password.
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    if (password != MockData.dummyPassword) {
      throw Exception('Invalid password');
    }

    try {
      final user = MockData.users.firstWhere((u) => u.email == email);
      await _saveUser(user);
      return user;
    } catch (e) {
      throw Exception('User not found');
    }
  }

  Future<User?> signup(String email, String password, String name, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if user already exists
    if (MockData.users.any((u) => u.email == email)) {
      throw Exception('User already exists');
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: role,
    );

    MockData.users.add(newUser);
    await _saveUser(newUser);
    return newUser;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
