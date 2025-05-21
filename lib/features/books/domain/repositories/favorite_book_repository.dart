import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/books/domain/repositories/book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class FavoriteBookRepository extends BookRepository{
  Future<ApiResult<List<BookItem>>> addFavoritedBook(BookItem bookItem);
  Future<ApiResult<List<BookItem>>> removeBookFromFavorite(BookItem bookItem);
}