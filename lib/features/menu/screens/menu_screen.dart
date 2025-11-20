import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../notes/screens/notes_list_screen.dart';
import '../../users/screens/users_list_screen.dart';
import '../../recipes/screens/recipe_list_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القائمة'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجراءات سريعة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/add-recipe'),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة وصفة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/favorites'),
                        icon: const Icon(Icons.favorite),
                        label: const Text('المفضلة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('جميع الوصفات'),
                  subtitle: const Text('استعراض جميع الوصفات المتاحة'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecipeListScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('الوصفات المفضلة'),
                  subtitle: const Text('الوصفات المحفوظة في المفضلة'),
                  onTap: () => context.go('/favorites'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.note_alt_outlined),
                  title: const Text('ملاحظاتي (Sqflite)'),
                  subtitle: const Text('إدارة الملاحظات المحلية'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotesListScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('إدارة المستخدمين (API)'),
                  subtitle: const Text('JSONPlaceholder - CRUD'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UsersListScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


