import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:korean_language_app/core/di/di.dart';
import 'package:korean_language_app/features/admin/presentation/pages/admin_management_page.dart';
import 'package:korean_language_app/features/admin/presentation/pages/admin_signup_page.dart';
import 'package:korean_language_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:korean_language_app/features/auth/presentation/pages/login_page.dart';
import 'package:korean_language_app/features/auth/presentation/pages/register_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/book_edit_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/books_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/favorite_books_page.dart';
import 'package:korean_language_app/features/books/presentation/pages/pdf_viewer_page.dart';
import 'package:korean_language_app/features/book_upload/presentation/pages/upload_books_page.dart';
import 'package:korean_language_app/features/home/presentation/pages/home_page.dart';
import 'package:korean_language_app/features/profile/presentation/pages/language_preference_page.dart';
import 'package:korean_language_app/features/profile/presentation/pages/profile_page.dart';
import 'package:korean_language_app/features/tests/presentation/pages/test_result_page.dart';
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
      final firebaseAuth = sl<FirebaseAuth>();
      final isLoggedIn = firebaseAuth.currentUser != null;
      final isGoingToLogin = state.matchedLocation == Routes.login;
      final isGoingToRegister = state.matchedLocation == Routes.register;
      final isGoingToForgotPassword = state.matchedLocation == Routes.forgotPassword;
      final isGoingToSplash = state.matchedLocation == Routes.splash;
      final isGoingToAdminSignup = state.matchedLocation == Routes.adminSignup;
      final isGoingToAuth = isGoingToLogin || isGoingToRegister || isGoingToForgotPassword || isGoingToAdminSignup;
      
      // Always allow access to splash screen
      if (isGoingToSplash) {
        return null;
      }
      
      // If not logged in, only allow access to auth pages
      if (!isLoggedIn) {
        if (isGoingToAuth) {
          return null; // Allow access to auth pages
        } else {
          return Routes.login; // Redirect to login for all other pages
        }
      }
      
      // If logged in, don't allow access to auth pages
      if (isLoggedIn && isGoingToAuth) {
        return Routes.home; // Redirect to home if trying to access auth pages while logged in
      }
      
      // Check admin access for admin-only routes
      if (state.matchedLocation == Routes.adminManagement) {
        // This will be checked inside the page with BlocBuilder
        // to avoid slowing down navigation with an extra Firestore query
        return null;
      }
      
      // Logged in user accessing an allowed page
      return null;
    },
    routes: [
      // Splash screen route
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
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
      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
            routes: const [
              // Nested routes for home if needed
            ],
          ),
          
          // Tests tab
          GoRoute(
            path: '/tests',
            name: 'tests',
            builder: (context, state) => const TestsPage(),
            routes: [
              //TODO: Implement Routing here
            ],
          ),

          // Books tab
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
          
          // Profile tab
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

  //Tests
  static const tests = '/tests';
  static const testsUpload = '/tests/upload';

  //Books
  static const books = '/books';
  static const pdfViewer = '/books/pdf-viewer';
  static const uploadBooks = '/books/upload-books';
  static const editBooks = '/books/edit-books';
  static const favoriteBooks = '/books/favorite-books';

  //Profile
  static const profile = '/profile';
  static const languagePreferences = '/profile/language-preferences';
  static const adminManagement = '/profile/admin-management';
  static const adminSignup = '$adminManagement/admin-signup';
  static const userManagement = '/profile/user-management';
}

// Scaffold with bottom navigation bar
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
       
        type: BottomNavigationBarType.fixed, //Change type to shifting if needed
        
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues( alpha : 0.6),
        
        // Make the labels visible (optional)
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