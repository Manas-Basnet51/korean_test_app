import 'package:korean_language_app/core/data/base_repository.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/core/network/network_info.dart';
import 'package:korean_language_app/features/books/data/datasources/favorite_books_local_data_source.dart';
import 'package:korean_language_app/features/books/domain/repositories/favorite_book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

class FavoriteBookRepositoryImpl extends BaseRepository implements FavoriteBookRepository {
  final FavoriteBooksLocalDataSource localDataSource;

  FavoriteBookRepositoryImpl({
    required this.localDataSource,
    required NetworkInfo networkInfo,
  }) : super(networkInfo);

  @override
  Future<ApiResult<void>> clearCachedBooks() {
    return handleRepositoryCall<void>(() async {
      return await localDataSource.clearCachedFavoriteBooks();
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooks(CourseCategory category, {int page = 0, int pageSize = 5}) {
    return getBooksFromCache();
  }

  @override
  Future<ApiResult<List<BookItem>>> getBooksFromCache() {
    return handleRepositoryCall<List<BookItem>>(() async {
      return await localDataSource.getCachedFavoriteBooks();
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> hardRefreshBooks(CourseCategory category, {int pageSize = 5}) {
    return getBooksFromCache();
  }

@override
Future<ApiResult<bool>> hasMoreBooks(CourseCategory category, int currentCount) {
  return handleRepositoryCall<bool>(() async {
    final result = await localDataSource.getCachedBooksCount();
    if (result.isSuccess) {
      return ApiResult.success(result.data! > currentCount);
    } else {
      return result.fold(
        onSuccess: (_) => ApiResult.success(false), // This branch won't be reached due to the if check
        onFailure: (msg, type) => ApiResult.failure(msg, type)
      );
    }
  });
}

  @override
  Future<ApiResult<List<BookItem>>> searchBooks(CourseCategory category, String query) {
    return handleRepositoryCall<List<BookItem>>(() async {
      final result = await localDataSource.getCachedFavoriteBooks();
      
      return result.fold(
        onSuccess: (books) {
          final normalizedQuery = query.toLowerCase();
          
          final filteredBooks = books.where((book) {
            return book.title.toLowerCase().contains(normalizedQuery) ||
                  book.description.toLowerCase().contains(normalizedQuery);
          }).toList();
          
          return ApiResult.success(filteredBooks);
        },
        onFailure: (message, type) {
          return ApiResult.failure(message, type);
        }
      );
    });
  }
  
  @override
  Future<ApiResult<List<BookItem>>> addFavoritedBook(BookItem bookItem) {
    return handleRepositoryCall<List<BookItem>>(() async {
      return await localDataSource.addFavoritedBook(bookItem);
    });
  }

  @override
  Future<ApiResult<List<BookItem>>> removeBookFromFavorite(BookItem bookItem) {
    return handleRepositoryCall<List<BookItem>>(() async {
      return await localDataSource.removeBookFromCache(bookItem.id);
    });
  }
}