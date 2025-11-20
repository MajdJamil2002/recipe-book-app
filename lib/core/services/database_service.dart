import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _notesKey = 'notes_list';
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Future<int> createNote({required String title, required String content}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      
      // إنشاء ID جديد (أكبر ID موجود + 1، أو 1 إذا كانت القائمة فارغة)
      int newId = 1;
      if (notesJson.isNotEmpty) {
        final existingNotes = notesJson
            .map((json) => jsonDecode(json) as Map<String, dynamic>)
            .toList();
        if (existingNotes.isNotEmpty) {
          final maxId = existingNotes
              .map((note) => note['id'] as int? ?? 0)
              .reduce((a, b) => a > b ? a : b);
          newId = maxId + 1;
        }
      }
      
      final note = {
        'id': newId,
        'title': title,
        'content': content,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      
      notesJson.add(jsonEncode(note));
      await prefs.setStringList(_notesKey, notesJson);
      
      return newId;
    } catch (e) {
      throw Exception('فشل في إنشاء الملاحظة: $e');
    }
  }

  Future<List<Map<String, Object?>>> getNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      
      if (notesJson.isEmpty) {
        return [];
      }
      
      final notes = notesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // ترتيب حسب التاريخ (من الأحدث للأقدم)
      notes.sort((a, b) {
        final aTime = a['created_at'] as int? ?? 0;
        final bTime = b['created_at'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });
      
      return notes.map((note) => note as Map<String, Object?>).toList();
    } catch (e) {
      throw Exception('فشل في تحميل الملاحظات: $e');
    }
  }

  Future<int> deleteNote(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      
      if (notesJson.isEmpty) {
        return 0;
      }
      
      final notes = notesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      final initialLength = notes.length;
      notes.removeWhere((note) => note['id'] == id);
      
      if (notes.length < initialLength) {
        final updatedNotesJson = notes.map((note) => jsonEncode(note)).toList();
        await prefs.setStringList(_notesKey, updatedNotesJson);
        return 1; // تم حذف ملاحظة واحدة
      }
      
      return 0; // لم يتم العثور على الملاحظة
    } catch (e) {
      throw Exception('فشل في حذف الملاحظة: $e');
    }
  }
}


