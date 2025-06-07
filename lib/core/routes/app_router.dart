import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/features/admin/presentation/pages/admin_management_page.dart';
import 'package:korean_language_app/features/admin/presentation/pages/admin_signup_page.dart';
import 'package:korean_language_app/features/admin/presentation/pages/migration_page.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:korean_language_app/features/auth/presentation/pages/login_page.dart';
import 'package:korean_language_app/features/auth/presentation/pages/register_page.dart';
import 'package:korean_language_app/features/book_upload/presentation/pages/book_edit_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/books_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/favorite_books_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/pdf_viewer_page.dart';
import 'package:korean_language_app/features/book_upload/presentation/pages/upload_books_page.dart';
import 'package:korean_language_app/features/home/presentation/pages/home_page.dart';
import 'package:korean_language_app/features/profile/presentation/pages/language_preference_page.dart';
import 'package:korean_language_app/features/profile/presentation/pages/profile_page.dart';
import 'package:korean_language_app/core/models/test_result.dart';
import 'package:korean_language_app/features/test_upload/presentation/pages/test_edit_page.dart';
import 'package:korean_language_app/features/test_results/presentation/pages/test_result_page.dart';
import 'package:korean_language_app/features/test_results/presentation/pages/test_results_history_page.dart';
import 'package:korean_language_app/features/tests/presentation/pages/test_taking_page.dart';
import 'package:korean_language_app/features/test_upload/presentation/pages/test_upload_page.dart';
import 'package:korean_language_app/features/tests/presentation/pages/tests_page.dart';
import 'package:korean_language_app/features/user_management/presentation/pages/user_management_page.dart';
import 'package:korean_language_app/core/presentation/widgets/splash/splash_screen.dart';

class AppRouter {
  static final AppRouter _instance = AppRouter._internal();

  AppRouter._internal();

  factory AppRouter() {
    return _instance;
  }

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authCubit = context.read<AuthCubit>();
      final authState = authCubit.state;
      
      // auth initial state
      if (authState is AuthInitial) {
        return Routes.splash;
      }
      
      final isLoggedIn = authState is Authenticated || authState is AuthAnonymousSignIn;
      
      // auth loading state
      if (authState is AuthLoading) {
        final isGoingToSplash = state.matchedLocation == Routes.splash;
        return isGoingToSplash ? null : Routes.splash;
      }
      
      // auth error state
      if (authState is AuthError) {
        final isGoingToAuth = [Routes.login, Routes.register, Routes.forgotPassword, Routes.adminSignup]
            .contains(state.matchedLocation);
        return isGoingToAuth ? null : Routes.login;
      }
      
      final isGoingToLogin = state.matchedLocation == Routes.login;
      final isGoingToRegister = state.matchedLocation == Routes.register;
      final isGoingToForgotPassword = state.matchedLocation == Routes.forgotPassword;
      final isGoingToSplash = state.matchedLocation == Routes.splash;
      final isGoingToAdminSignup = state.matchedLocation == Routes.adminManagement + Routes.adminSignup;
      final isGoingToAuth = isGoingToLogin || isGoingToRegister || isGoingToForgotPassword || isGoingToAdminSignup;
      
      if (isGoingToSplash && authState is! AuthLoading) {
        return isLoggedIn ? Routes.home : Routes.login;
      }
      
      if (!isLoggedIn) {
        return isGoingToAuth ? null : Routes.login;
      }
      
      if (isLoggedIn && isGoingToAuth) {
        return Routes.home;
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          
          GoRoute(
            path: '/tests',
            name: 'tests',
            builder: (context, state) => const TestsPage(),
            routes: [
              GoRoute(
                path: 'take/:testId',
                name: 'testTaking',
                builder: (context, state) {
                  final testId = state.pathParameters['testId']!;
                  return TestTakingPage(testId: testId);
                },
              ),
              GoRoute(
                path: 'upload',
                name: 'testUpload',
                builder: (context, state) => const TestUploadPage(),
              ),
              GoRoute(
                path: 'edit/:testId',
                name: 'testEdit',
                builder: (context, state) {
                  final testId = state.pathParameters['testId']!;
                  return TestEditPage(testId: testId);
                },
              ),
              GoRoute(
                path: 'results',
                name: 'testResults',
                builder: (context, state) => const TestResultsHistoryPage(),
              ),
              GoRoute(
                path: 'result',
                name: 'testResult',
                builder: (context, state) {
                  final result = state.extra as TestResult;
                  return TestResultPage(result: result);
                },
              ),
            ],
          ),

          GoRoute(
            path: '/books',
            name: 'books',
            builder: (context, state) => const BooksPage(),
            routes: [
              GoRoute(
                path: 'pdf-viewer',
                name: 'pdfViewer',
                builder: (context, state) {
                  final pdfFile = state.extra as PDFViewerScreen;
                  return PDFViewerScreen(
                    pdfFile: pdfFile.pdfFile,
                    title: pdfFile.title,
                  );
                },
              ),
              GoRoute(
                path: 'upload-books',
                name: 'uploadBooks',
                builder: (context, state) => const BookUploadPage(),
              ),
              GoRoute(
                path: 'edit-books',
                name: 'editBooks',
                builder: (context, state) {
                  final extra = state.extra as BookEditPage;
                  return BookEditPage(book: extra.book);
                },
              ),
              GoRoute(
                path: 'favorite-books',
                name: 'favoriteBooks',
                builder: (context, state) => const FavoriteBooksPage(),
              ),
            ],
          ),
          
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'language-preferences',
                name: 'languagePreferences',
                builder: (context, state) => const LanguagePreferencePage(),
              ),
              GoRoute(
                path: 'admin-management',
                name: 'adminManagement',
                builder: (context, state) => const AdminManagementPage(),
                routes: [
                  GoRoute(
                    path: 'admin-signup',
                    name: 'adminSignup',
                    builder: (context, state) => const AdminSignupPage(),
                  ),
                  GoRoute(
                    path: 'migration-page',
                    name: 'migrationPage',
                    builder: (context, state) => const MigrationPage(),
                  ),
                ]
              ),
              GoRoute(
                path: 'user-management',
                name: 'userManagement',
                builder: (context, state) => const UserManagementPage(),
              ),
            ]
          ),
        ],
      ),
    ],
  );
}

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';

  static const tests = '/tests';
  static const testUpload = '/tests/upload';
  static const testResults = '/tests/results';
  static const testResult = '/tests/result';

  static const books = '/books';
  static const pdfViewer = '/books/pdf-viewer';
  static const uploadBooks = '/books/upload-books';
  static const editBooks = '/books/edit-books';
  static const favoriteBooks = '/books/favorite-books';

  static const profile = '/profile';
  static const languagePreferences = '/profile/language-preferences';
  static const adminManagement = '/profile/admin-management';
  static const adminMigrationPage = '$adminManagement/migration-page';
  static const adminSignup = '$adminManagement/admin-signup';
  static const userManagement = '/profile/user-management';

  // Helper methods for parameterized routes
  static String testTaking(String testId) => '/tests/take/$testId';
  static String testEdit(String testId) => '/tests/edit/$testId';
}

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;
  
  const ScaffoldWithBottomNavBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/tests')) {
      return 1;
    }
    if (location.startsWith('/books')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/tests');
        break;
      case 2:
        GoRouter.of(context).go('/books');
        break;
      case 3:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}