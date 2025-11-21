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
      final savedEmail = prefs.getString(_emailKey);
      
      if (_isLoggedIn && savedEmail != null) {
        final cleanEmail = savedEmail.trim().toLowerCase();
        final usersJson = prefs.getString(_usersKey);
        
        if (usersJson != null && usersJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
            final Map<String, String> users = decoded.map(
              (key, value) => MapEntry(key.toString().toLowerCase(), value.toString()),
            );
            
            if (!users.containsKey(cleanEmail)) {
              // الحساب غير موجود، تسجيل خروج
              _isLoggedIn = false;
              _email = null;
              await prefs.setBool(_isLoggedInKey, false);
              await prefs.remove(_emailKey);
            } else {
              // تحديث البريد الإلكتروني إلى الصيغة الموحدة
              _email = cleanEmail;
              if (savedEmail != cleanEmail) {
                await prefs.setString(_emailKey, cleanEmail);
              }
            }
          } catch (e) {
            // بيانات تالفة، تسجيل خروج
            _isLoggedIn = false;
            _email = null;
            await prefs.setBool(_isLoggedInKey, false);
            await prefs.remove(_emailKey);
          }
        } else {
          // لا توجد بيانات مستخدمين، تسجيل خروج
          _isLoggedIn = false;
          _email = null;
          await prefs.setBool(_isLoggedInKey, false);
          await prefs.remove(_emailKey);
        }
      } else {
        _email = null;
      }
      
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      _email = null;
      notifyListeners();
    }
  }

  Future<void> register({required String email, required String password}) async {
    try {
      // تنظيف البريد الإلكتروني
      final cleanEmail = email.trim().toLowerCase();
      
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      Map<String, String> users = <String, String>{};
      if (usersJson != null && usersJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
          users = decoded.map(
            (key, value) => MapEntry(key.toString().toLowerCase(), value.toString()),
          );
        } catch (e) {
          // في حالة وجود بيانات تالفة، نبدأ من جديد
          users = <String, String>{};
        }
      }

      if (users.containsKey(cleanEmail)) {
        final storedPassword = users[cleanEmail];
        if (storedPassword == password) {
          // كلمة المرور صحيحة، سجّل دخول المستخدم
          _isLoggedIn = true;
          _email = cleanEmail;
          final success1 = await prefs.setBool(_isLoggedInKey, true);
          final success2 = await prefs.setString(_emailKey, cleanEmail);
          if (!success1 || !success2) {
            throw Exception('فشل في حفظ حالة تسجيل الدخول');
          }
          notifyListeners();
          return;
        } else {
          throw Exception('هذا البريد مسجّل مسبقًا بكلمة مرور مختلفة');
        }
      }

      // إنشاء حساب جديد
      users[cleanEmail] = password;
      
      final success1 = await prefs.setString(_usersKey, jsonEncode(users));
      if (!success1) {
        throw Exception('فشل في حفظ بيانات المستخدم');
      }
      
      _isLoggedIn = true;
      _email = cleanEmail;
      final success2 = await prefs.setBool(_isLoggedInKey, true);
      final success3 = await prefs.setString(_emailKey, cleanEmail);
      if (!success2 || !success3) {
        throw Exception('فشل في حفظ حالة تسجيل الدخول');
      }
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      _email = null;
      notifyListeners();
      // إعادة رمي الخطأ مع رسالة واضحة
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('خطأ في التسجيل: $e');
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      // تنظيف البريد الإلكتروني
      final cleanEmail = email.trim().toLowerCase();
      
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null || usersJson.isEmpty) {
        throw Exception('لا توجد حسابات مسجلة. يرجى إنشاء حساب جديد');
      }
      
      final Map<String, dynamic> decoded = jsonDecode(usersJson) as Map<String, dynamic>;
      final Map<String, String> users = decoded.map(
        (key, value) => MapEntry(key.toString().toLowerCase(), value.toString()),
      );

      if (!users.containsKey(cleanEmail)) {
        throw Exception('البريد الإلكتروني غير مسجل. يرجى التحقق من البيانات أو إنشاء حساب جديد');
      }

      final storedPassword = users[cleanEmail];
      if (storedPassword == null || storedPassword != password) {
        throw Exception('كلمة المرور غير صحيحة');
      }

      _isLoggedIn = true;
      _email = cleanEmail;
      final success1 = await prefs.setBool(_isLoggedInKey, true);
      final success2 = await prefs.setString(_emailKey, cleanEmail);
      if (!success1 || !success2) {
        throw Exception('فشل في حفظ حالة تسجيل الدخول');
      }
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      _email = null;
      notifyListeners();
      // إعادة رمي الخطأ مع رسالة واضحة
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('خطأ في تسجيل الدخول: $e');
      }
    }
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


