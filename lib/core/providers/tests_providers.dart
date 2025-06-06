import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/di/di.dart';
import 'package:korean_language_app/features/test_results/presentation/bloc/test_results_cubit.dart';
import 'package:korean_language_app/features/test_upload/presentation/bloc/test_upload_cubit.dart';
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
      BlocProvider<TestUploadCubit>(
        create: (context) => sl<TestUploadCubit>(),
      ),
      BlocProvider<TestResultsCubit>(
        create: (context) => sl<TestResultsCubit>(),
      ),
      // Add other book category cubits here as needed
    ];
  }
}