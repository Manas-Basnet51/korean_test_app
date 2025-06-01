import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/di/di.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/test_session/test_session_cubit.dart';
import 'package:korean_language_app/features/tests/presentation/bloc/tests_cubit.dart';

class TestsProviders {
  static List<BlocProvider> getProviders() {
    return [
      BlocProvider<TestsCubit>(
        create: (context) => sl<TestsCubit>(),
      ),
      BlocProvider<TestSessionCubit>(
        create: (context) => sl<TestSessionCubit>(),
      ),
      // Add other book category cubits here as needed
    ];
  }
}