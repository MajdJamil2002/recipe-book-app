import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final recipe = await _recipeService.getRecipeById(widget.recipeId);
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الوصفة: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_recipe == null) return;

    try {
      final updatedRecipe = _recipe!.copyWith(isFavorite: !_recipe!.isFavorite);
      await _recipeService.updateRecipe(updatedRecipe);
      setState(() {
        _recipe = updatedRecipe;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedRecipe.isFavorite ? 'تمت إضافة الوصفة للمفضلة' : 'تمت إزالة الوصفة من المفضلة'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث المفضلة: $e'),
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
        title: const Text('تفاصيل الوصفة'),
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
          if (_recipe != null)
            IconButton(
              icon: Icon(
                _recipe!.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _recipe!.isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
              ? const Center(
                  child: Text(
                    'الوصفة غير موجودة',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        child: Image.network(
                          _recipe!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant, size: 80),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recipe!.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _recipe!.description,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoCard(
                                    icon: Icons.access_time,
                                    title: 'وقت الطهي',
                                    value: '${_recipe!.cookingTime} دقيقة',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _InfoCard(
                                    icon: Icons.people,
                                    title: 'عدد الحصص',
                                    value: '${_recipe!.servings} أشخاص',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _InfoCard(
                                    icon: Icons.category,
                                    title: 'الفئة',
                                    value: _recipe!.category,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'المكونات',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: _recipe!.ingredients.map((ingredient) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.circle, size: 8, color: Colors.orange),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              ingredient,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'طريقة التحضير',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: _recipe!.instructions.asMap().entries.map((entry) {
                                    final index = entry.key + 1;
                                    final instruction = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$index',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              instruction,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
