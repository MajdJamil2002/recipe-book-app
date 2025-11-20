import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const String _usersKey = 'auth_users_json';
  static const String _isLoggedInKey = 'auth_is_logged_in';
  static const String _emailKey = 'auth_email';

  static final AuthService instance = AuthService._internal();

  AuthService._internal();

  bool _isLoggedIn = false;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  String? get email => _email;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      _email = prefs.getString(_emailKey);
      
      if (_isLoggedIn && _email != null) {
        final usersJson = prefs.getString(_usersKey);
        if (usersJson != null) {
          final Map<String, String> users = Map<String, String>.from(jsonDecode(usersJson) as Map);
          if (!users.containsKey(_email)) {
            _isLoggedIn = false;
            _email = null;
            await prefs.setBool(_isLoggedInKey, false);
            await prefs.remove(_emailKey);
          }
        } else {
          _isLoggedIn = false;
          _email = null;
          await prefs.setBool(_isLoggedInKey, false);
          await prefs.remove(_emailKey);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      _email = null;
      notifyListeners();
    }
  }

  Future<void> register({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final Map<String, String> users = usersJson == null
        ? <String, String>{}
        : Map<String, String>.from(jsonDecode(usersJson) as Map);

    if (users.containsKey(email)) {
      final storedPassword = users[email];
      if (storedPassword == password) {
        _isLoggedIn = true;
        _email = email;
        final success1 = await prefs.setBool(_isLoggedInKey, true);
        final success2 = await prefs.setString(_emailKey, email);
        if (!success1 || !success2) {
          throw Exception('فشل في حفظ حالة تسجيل الدخول');
        }
        notifyListeners();
        return;
      } else {
        throw Exception('هذا البريد مسجّل مسبقًا بكلمة مرور مختلفة');
      }
    }

    users[email] = password;
    
    final success1 = await prefs.setString(_usersKey, jsonEncode(users));
    if (!success1) {
      throw Exception('فشل في حفظ بيانات المستخدم');
    }
    
    _isLoggedIn = true;
    _email = email;
    final success2 = await prefs.setBool(_isLoggedInKey, true);
    final success3 = await prefs.setString(_emailKey, email);
    if (!success2 || !success3) {
      throw Exception('فشل في حفظ حالة تسجيل الدخول');
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final Map<String, String> users = usersJson == null
        ? <String, String>{}
        : Map<String, String>.from(jsonDecode(usersJson) as Map);

    final stored = users[email];
    if (stored == null || stored != password) {
      throw Exception('بيانات الدخول غير صحيحة');
    }

    _isLoggedIn = true;
    _email = email;
    final success1 = await prefs.setBool(_isLoggedInKey, true);
    final success2 = await prefs.setString(_emailKey, email);
    if (!success1 || !success2) {
      throw Exception('فشل في حفظ حالة تسجيل الدخول');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    _email = null;
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_emailKey);
    notifyListeners();
  }
}


