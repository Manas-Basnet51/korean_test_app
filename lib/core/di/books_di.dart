// lib/core/di/feature_di/books_di.dart
import 'package:get_it/get_it.dart';
import 'package:korean_language_app/features/book_upload/data/datasources/book_upload_remote_datasource.dart';
import 'package:korean_language_app/features/book_upload/data/datasources/book_upload_remote_datasource_impl.dart';
import 'package:korean_language_app/features/book_upload/data/repositories/book_upload_repository_impl.dart';
import 'package:korean_language_app/features/book_upload/domain/repositories/book_upload_repository.dart';
import 'package:korean_language_app/features/book_upload/presentation/bloc/file_upload_cubit.dart';
import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source.dart';
import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source_impl.dart';
import 'package:korean_language_app/features/books/data/datasources/firestore_korean_books_remote_data_source_impl.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_local_data_source_impl.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_local_datasource.dart';
import 'package:korean_language_app/features/books/data/datasources/korean_books_remote_data_source.dart';
import 'package:korean_language_app/features/books/data/repositories/favorite_book_repository_impl.dart';
import 'package:korean_language_app/features/books/data/repositories/korean_book_repository_impl.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/domain/repositories/korean_book_repository.dart';
import 'package:korean_language_app/features/books/presentation/bloc/favorite_books/favorite_books_cubit.dart';
import 'package:korean_language_app/features/books/presentation/bloc/korean_books/korean_books_cubit.dart';

void registerBooksDependencies(GetIt sl) {
  // Cubits
  sl.registerFactory(() => KoreanBooksCubit(
    repository: sl(),
    authService: sl(),
    adminService: sl(),
  ));

  sl.registerFactory(() => FavoriteBooksCubit(sl()));
  
  // Upload related
  sl.registerFactory(() => FileUploadCubit(
    uploadRepository: sl(),
    authService: sl(),
  ));
  
  sl.registerLazySingleton<BookUploadRepository>(
    () => BookUploadRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      adminService: sl(),
    )
  );
  
  sl.registerLazySingleton<BookUploadRemoteDataSource>(
    () => FirestoreBookUploadDataSource(
      firestore: sl(),
      storage: sl(),
    )
  );
  
  // Repositories
  sl.registerLazySingleton<KoreanBookRepository>(
    () => KoreanBookRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    )
  );
  
  sl.registerLazySingleton<FavoriteBookRepository>(
    () => FavoriteBookRepositoryImpl(
      localDataSource: sl(),
      networkInfo: sl(),
    )
  );
  
  // Data sources
  sl.registerLazySingleton<KoreanBooksRemoteDataSource>(
    () => FirestoreKoreanBooksDataSource(firestore: sl(), storage: sl()),
  );
  
  sl.registerLazySingleton<KoreanBooksLocalDataSource>(
    () => KoreanBooksLocalDataSourceImpl(storageService: sl())
  );
  
  sl.registerLazySingleton<FavoriteBooksLocalDataSource>(
    () => FavoriteBooksLocalDataSourceImpl(storageService: sl()) // Changed parameter
  );
}