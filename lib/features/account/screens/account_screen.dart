import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/theme_service.dart';
import '../../recipes/services/recipe_service.dart';
import '../../../core/services/database_service.dart';
import '../../notes/screens/notes_list_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final RecipeService _recipeService = RecipeService();
  int _totalRecipes = 0;
  int _favoriteCount = 0;
  int _notesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final allRecipes = await _recipeService.getAllRecipes();
      final favorites = await _recipeService.getFavoriteRecipes();
      final notes = await DatabaseService.instance.getNotes();
      
      if (mounted) {
        setState(() {
          _totalRecipes = allRecipes.length;
          _favoriteCount = favorites.length;
          _notesCount = notes.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userEmail = authService.email ?? 'غير محدد';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
            IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مرحباً بك!',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'إحصائيات سريعة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.menu_book,
                          title: 'الوصفات',
                          value: '$_totalRecipes',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.favorite,
                          title: 'المفضلة',
                          value: '$_favoriteCount',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 12),
            _isLoading
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.note_alt,
                          title: 'الملاحظات',
                          value: '$_notesCount',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            
            Text(
              'إجراءات',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('الوصفات المفضلة'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/favorites'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('إضافة وصفة جديدة'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/add-recipe'),
            ),
            ListTile(
              leading: const Icon(Icons.note_alt),
              title: const Text('ملاحظاتي'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotesListScreen(),
                  ),
                ).then((_) {
                  // إعادة تحميل الإحصائيات عند العودة
                  _loadStats();
                });
              },
            ),
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                final isDark = themeService.themeMode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: Text(isDark ? 'الوضع الداكن' : 'الوضع الفاتح'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      themeService.toggleDarkLight();
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                await authService.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
