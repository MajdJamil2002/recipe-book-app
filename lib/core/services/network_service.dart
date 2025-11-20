import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration timeout = Duration(seconds: 10);

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(timeout);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('فشل في تحميل المستخدمين: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUser(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(timeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في تحميل المستخدم: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String phone,
    required String website,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'website': website,
        'username': name.toLowerCase().replaceAll(' ', '_'),
      }),
    ).timeout(timeout);
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في إنشاء المستخدم: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String website,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'website': website,
        'username': name.toLowerCase().replaceAll(' ', '_'),
      }),
    ).timeout(timeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('فشل في تحديث المستخدم: ${response.statusCode}');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(timeout);
    
    if (response.statusCode != 200) {
      throw Exception('فشل في حذف المستخدم: ${response.statusCode}');
    }
  }
}
