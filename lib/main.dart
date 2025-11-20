import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/recipes/screens/recipe_list_screen.dart';
import 'features/recipes/screens/recipe_detail_screen.dart';
import 'features/recipes/screens/add_recipe_screen.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/menu/screens/menu_screen.dart';
import 'features/account/screens/account_screen.dart';
import 'shared/widgets/app_shell.dart';
import 'core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  await ThemeService.instance.init();
  runApp(const RecipeBookApp());
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AuthService.instance),
        ChangeNotifierProvider.value(value: ThemeService.instance),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'كتاب الوصفات',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 2,
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 2,
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            themeMode: themeService.themeMode,
            routerConfig: _createRouter(),
          );
        },
      ),
    );
  }
}

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = AuthService.instance.isLoggedIn;
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    refreshListenable: AuthService.instance,
    routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/menu',
              name: 'menu',
              builder: (context, state) => const MenuScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              name: 'favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/add-recipe',
              name: 'add-recipe',
              builder: (context, state) => const AddRecipeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              name: 'account',
              builder: (context, state) => const AccountScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/recipes',
      name: 'recipes',
      builder: (context, state) => const RecipeListScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      name: 'recipe-detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RecipeDetailScreen(recipeId: id);
      },
    ),
    GoRoute(
      path: '/edit-recipe/:id',
      name: 'edit-recipe',
      builder: (context, state) {
        return const Scaffold();
      },
    ),
  ],
  );
}