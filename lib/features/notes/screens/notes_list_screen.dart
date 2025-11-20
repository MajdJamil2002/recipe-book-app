import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  bool _loading = true;
  List<Map<String, Object?>> _notes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notes = await DatabaseService.instance.getNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الملاحظات: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _addNote() async {
    final created = await Navigator.of(context).push<Map<String, Object?>>(
      MaterialPageRoute(builder: (_) => const _AddNoteScreen()),
    );
    if (created != null) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملاحظاتي'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('لا توجد ملاحظات بعد'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Dismissible(
                      key: ValueKey(note['id']),
                      background: Container(color: Colors.red),
                      onDismissed: (_) async {
                        try {
                          await DatabaseService.instance.deleteNote(note['id'] as int);
                          if (mounted) {
                            _load();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم حذف الملاحظة'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ في حذف الملاحظة: $e'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            _load(); // إعادة تحميل لإعادة الملاحظة المحذوفة
                          }
                        }
                      },
                      child: ListTile(
                        title: Text(note['title'] as String),
                        subtitle: Text(
                          note['content'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AddNoteScreen extends StatefulWidget {
  const _AddNoteScreen();

  @override
  State<_AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<_AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل العنوان والمحتوى'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() => _saving = true);
    
    try {
      await DatabaseService.instance.createNote(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملاحظة بنجاح'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop({'ok': true});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الملاحظة: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة ملاحظة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'المحتوى', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}


