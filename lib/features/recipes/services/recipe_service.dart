import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/recipe.dart';

class RecipeService {
  static const String _recipesKey = 'recipes';

  Future<List<Recipe>> getAllRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipesJson = prefs.getStringList(_recipesKey) ?? [];
      
      if (recipesJson.isEmpty) {
        return _getSampleRecipes();
      }
      
      return recipesJson
          .map((json) => Recipe.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      throw Exception('فشل في تحميل الوصفات: $e');
    }
  }

  Future<Recipe?> getRecipeById(String id) async {
    try {
      final recipes = await getAllRecipes();
      return recipes.firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    try {
      final recipes = await getAllRecipes();
      recipes.add(recipe);
      await _saveRecipes(recipes);
    } catch (e) {
      throw Exception('فشل في إضافة الوصفة: $e');
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      final recipes = await getAllRecipes();
      final index = recipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        recipes[index] = recipe;
        await _saveRecipes(recipes);
      }
    } catch (e) {
      throw Exception('فشل في تحديث الوصفة: $e');
    }
  }

  Future<void> deleteRecipe(String id) async {
    try {
      final recipes = await getAllRecipes();
      recipes.removeWhere((recipe) => recipe.id == id);
      await _saveRecipes(recipes);
    } catch (e) {
      throw Exception('فشل في حذف الوصفة: $e');
    }
  }

  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      final recipes = await getAllRecipes();
      return recipes.where((recipe) => recipe.isFavorite).toList();
    } catch (e) {
      throw Exception('فشل في تحميل الوصفات المفضلة: $e');
    }
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final recipes = await getAllRecipes();
      return recipes.where((recipe) => recipe.category == category).toList();
    } catch (e) {
      throw Exception('فشل في تحميل وصفات الفئة: $e');
    }
  }

  Future<void> _saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = recipes
        .map((recipe) => jsonEncode(recipe.toJson()))
        .toList();
    await prefs.setStringList(_recipesKey, recipesJson);
  }

  List<Recipe> _getSampleRecipes() {
    return [
      Recipe(
        id: '1',
        title: 'كبسة الدجاج',
        description: 'وصفة كبسة دجاج تقليدية لذيذة ومشبعة',
        ingredients: [
          '2 كوب أرز بسمتي',
          '1 دجاجة مقطعة',
          '2 بصل متوسط',
          '3 فصوص ثوم',
          '2 حبة طماطم',
          'ملح وفلفل أسود',
          'هيل وقرنفل',
          'زعفران',
        ],
        instructions: [
          'اغسل الأرز ونقعه في الماء لمدة 30 دقيقة',
          'اقلي البصل حتى يصبح ذهبياً',
          'أضف الدجاج وقلبه حتى يتحمر',
          'أضف الطماطم والبهارات',
          'أضف الماء واتركه يغلي',
          'أضف الأرز واتركه ينضج على نار هادئة',
        ],
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03246963d4d4?w=400',
        cookingTime: 60,
        servings: 6,
        category: 'أطباق رئيسية',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Recipe(
        id: '2',
        title: 'تشيز كيك الفراولة',
        description: 'تشيز كيك كريمي مع طبقة فراولة لذيذة',
        ingredients: [
          '200 جرام بسكويت',
          '100 جرام زبدة',
          '500 جرام جبن كريمي',
          '200 جرام سكر',
          '3 بيضات',
          '200 مل كريمة',
          'فراولة طازجة',
          'جل الفراولة',
        ],
        instructions: [
          'اهرس البسكويت واخلطه مع الزبدة',
          'اضغط الخليط في قاع القالب',
          'اخفق الجبن مع السكر',
          'أضف البيض والكريمة',
          'اسكب الخليط على البسكويت',
          'اخبز في الفرن لمدة 45 دقيقة',
          'زين بالفراولة والجل',
        ],
        imageUrl: 'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=400',
        cookingTime: 90,
        servings: 8,
        category: 'حلويات',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Recipe(
        id: '3',
        title: 'سلطة الكينوا',
        description: 'سلطة صحية ومغذية مع الكينوا والخضروات',
        ingredients: [
          '1 كوب كينوا',
          'خيار مقطع',
          'طماطم كرزية',
          'فلفل ملون',
          'بقدونس طازج',
          'زيت زيتون',
          'عصير ليمون',
          'ملح وفلفل',
        ],
        instructions: [
          'اطبخ الكينوا حسب التعليمات',
          'اتركها تبرد',
          'قطع الخضروات قطع صغيرة',
          'اخلط الكينوا مع الخضروات',
          'أضف البقدونس',
          'اخلط زيت الزيتون مع الليمون',
          'اسكب الصلصة على السلطة',
        ],
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        cookingTime: 25,
        servings: 4,
        category: 'سلطات',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
