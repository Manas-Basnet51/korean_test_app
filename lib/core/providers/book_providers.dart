import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/di/di.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';

class BookProviders {
  static List<BlocProvider> getProviders() {
    return [
      BlocProvider<KoreanBooksCubit>(
        create: (context) => sl<KoreanBooksCubit>(),
      ),
      BlocProvider<FavoriteBooksCubit>(
        create: (context) => sl<FavoriteBooksCubit>(),
      ),
      // Add other book category cubits here as needed
    ];
  }
}