import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/recipe.dart';
import '../../recipes/services/recipe_service.dart';
import '../../auth/services/auth_service.dart';
import 'package:flutter/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RecipeService _recipeService = RecipeService();
  List<Recipe> _recentRecipes = [];
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDashboardData();
        }
      });
    }
  }


  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final allRecipes = await _recipeService.getAllRecipes();
      final favorites = await _recipeService.getFavoriteRecipes();
      
      final sortedRecipes = List<Recipe>.from(allRecipes);
      sortedRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _recentRecipes = sortedRecipes.take(3).toList();
        _favoriteRecipes = favorites.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userEmail = authService.email ?? 'مستخدم';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _DashboardBody(
        isLoading: _isLoading,
        recentRecipes: _recentRecipes,
        favoriteRecipes: _favoriteRecipes,
        userEmail: userEmail,
        onRefresh: _loadDashboardData,
        recipeService: _recipeService,
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  final bool isLoading;
  final List<Recipe> recentRecipes;
  final List<Recipe> favoriteRecipes;
  final String userEmail;
  final VoidCallback onRefresh;
  final RecipeService recipeService;

  const _DashboardBody({
    required this.isLoading,
    required this.recentRecipes,
    required this.favoriteRecipes,
    required this.userEmail,
    required this.onRefresh,
    required this.recipeService,
  });

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  int _totalRecipes = 0;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTotalRecipes();
  }

  Future<void> _loadTotalRecipes() async {
    try {
      final allRecipes = await widget.recipeService.getAllRecipes();
      if (mounted) {
        setState(() {
          _totalRecipes = allRecipes.length;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  @override
  void didUpdateWidget(_DashboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة تحميل العدد الإجمالي عند تغيير الوصفات
    if (oldWidget.recentRecipes.length != widget.recentRecipes.length) {
      _loadTotalRecipes();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تحميل العدد الإجمالي عند فتح الشاشة (مرة واحدة فقط)
    if (!_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadTotalRecipes();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeCard(userEmail: widget.userEmail),
            const SizedBox(height: 20),
            
            _StatsSection(
              totalRecipes: _totalRecipes,
              favoriteCount: widget.favoriteRecipes.length,
            ),
            const SizedBox(height: 20),
            
            _QuickActionsSection(),
            const SizedBox(height: 20),
            
            if (widget.recentRecipes.isNotEmpty) ...[
              _SectionTitle(
                title: 'الوصفات الحديثة',
                onTap: () => context.go('/recipes'),
              ),
              const SizedBox(height: 12),
              _RecentRecipesList(recipes: widget.recentRecipes),
              const SizedBox(height: 20),
            ],
            
            if (widget.favoriteRecipes.isNotEmpty) ...[
              _SectionTitle(
                title: 'الوصفات المفضلة',
                onTap: () => context.go('/favorites'),
              ),
              const SizedBox(height: 12),
              _FavoriteRecipesList(recipes: widget.favoriteRecipes),
            ],
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userEmail;

  const _WelcomeCard({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
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
                  const SizedBox(height: 8),
                  Text(
                    'استكشف وصفات جديدة وأضف المفضلة لديك',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int totalRecipes;
  final int favoriteCount;

  const _StatsSection({
    required this.totalRecipes,
    required this.favoriteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book,
            title: 'إجمالي الوصفات',
            value: '$totalRecipes',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            title: 'المفضلة',
            value: '$favoriteCount',
            color: Colors.red,
          ),
        ),
      ],
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
            Icon(icon, size: 28, color: color),
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

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/favorites'),
                icon: const Icon(Icons.favorite),
                label: const Text('المفضلة'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionTitle({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('عرض الكل'),
        ),
      ],
    );
  }
}

class _RecentRecipesList extends StatelessWidget {
  final List<Recipe> recipes;

  const _RecentRecipesList({required this.recipes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => context.go('/recipe/${recipe.id}'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.cookingTime}د',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteRecipesList extends StatelessWidget {
  final List<Recipe> recipes;

  const _FavoriteRecipesList({required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: recipes.map((recipe) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.favorite, color: Colors.red, size: 20),
            ),
            title: Text(recipe.title),
            subtitle: Text('${recipe.cookingTime} دقيقة'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/recipe/${recipe.id}'),
          ),
        );
      }).toList(),
    );
  }
}


