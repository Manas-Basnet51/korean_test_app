import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/di/di.dart' as di;
import 'package:korean_language_app/core/providers/tests_providers.dart';
import 'package:korean_language_app/core/routes/app_router.dart';
import 'package:korean_language_app/core/presentation/theme/constants/app_theme.dart';
import 'package:korean_language_app/firebase_options.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/core/presentation/connectivity/bloc/connectivity_cubit.dart';
import 'package:korean_language_app/features/book_upload/presentation/bloc/file_upload_cubit.dart';
import 'package:korean_language_app/core/presentation/language_preference/bloc/language_preference_cubit.dart';
import 'package:korean_language_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:korean_language_app/core/presentation/snackbar/bloc/snackbar_cubit.dart';
import 'package:korean_language_app/core/presentation/theme/bloc/theme_cubit.dart';
import 'package:korean_language_app/core/providers/admin_providers.dart';
import 'package:korean_language_app/core/providers/book_providers.dart';
import 'package:korean_language_app/core/presentation/snackbar/widgets/snackbar_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();

  // debugRepaintRainbowEnabled = true; // Good for checking repaints caused by rendering
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SnackBarCubit>(
          create: (context) => di.sl<SnackBarCubit>(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => di.sl<AuthCubit>(),
        ),
        BlocProvider<ProfileCubit>(
          create: (context) => di.sl<ProfileCubit>(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => di.sl<ThemeCubit>(),
        ),
        BlocProvider<LanguagePreferenceCubit>(
          create: (context) => di.sl<LanguagePreferenceCubit>(),
        ),
        BlocProvider<FileUploadCubit>(
          create: (context) => di.sl<FileUploadCubit>(),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (context) => di.sl<ConnectivityCubit>(),
        ),
        ...BookProviders.getProviders(),
        ...AdminProviders.getProviders(),
        ...TestsProviders.getProviders(),
        // Add other BLoC providers here
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) {
          return (previous.runtimeType != current.runtimeType) &&
                (current is Authenticated || 
                  current is Unauthenticated || 
                  current is AuthAnonymousSignIn ||
                  current is AuthLoading);
        },
        listener: (context, state) {
          AppRouter.router.refresh();
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'Korean Test App',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: AppRouter.router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return SnackBarWidget(
                  child: child ?? const SizedBox(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //Appchecks or storage checks
}
