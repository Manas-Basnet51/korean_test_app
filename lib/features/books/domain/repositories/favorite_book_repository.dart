import 'package:korean_language_app/features/books/domain/repositories/book_repository.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';

abstract class FavoriteBookRepository extends BookRepository{
  Future<List<BookItem>> addFavoritedBook(BookItem bookItem);
  Future<List<BookItem>> removeBookFromFavorite(BookItem bookItem);
}