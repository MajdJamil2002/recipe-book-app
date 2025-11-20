import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/recipe.dart';
import '../services/recipe_service.dart';
import '../../auth/services/auth_service.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _selectedCategory = 'الكل';

  final List<String> _categories = [
    'الكل',
    'أطباق رئيسية',
    'حلويات',
    'مشروبات',
    'سلطات',
    'شوربات',
    'وجبات خفيفة',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await _recipeService.getAllRecipes();
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الوصفات: $e')),
        );
      }
    }
  }

  List<Recipe> get _filteredRecipes {
    if (_selectedCategory == 'الكل') {
      return _recipes;
    }
    return _recipes.where((recipe) => recipe.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كتاب الوصفات'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) context.go('/login');
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => context.go('/favorites'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecipes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد وصفات متاحة',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecipes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _filteredRecipes[index];
                            return RecipeCard(
                              recipe: recipe,
                              onTap: () => context.go('/recipe/${recipe.id}'),
                              onFavoriteToggle: () => _toggleFavorite(recipe),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-recipe'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    try {
      final updatedRecipe = recipe.copyWith(isFavorite: !recipe.isFavorite);
      await _recipeService.updateRecipe(updatedRecipe);
      setState(() {
        final index = _recipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _recipes[index] = updatedRecipe;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedRecipe.isFavorite 
                ? 'تم إضافة "${recipe.title}" إلى المفضلة' 
                : 'تم إزالة "${recipe.title}" من المفضلة'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديث المفضلة: $e')),
        );
      }
    }
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  recipe.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 40),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookingTime} دقيقة',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servings} أشخاص',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: recipe.isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: onFavoriteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
