import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/data/base_state.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
import 'package:korean_language_app/core/errors/api_result.dart';
import 'package:korean_language_app/features/admin/data/service/admin_permission.dart';
import 'package:korean_language_app/features/auth/domain/entities/user.dart';
import 'package:korean_language_app/features/books/domain/repositories/korean_book_repository.dart';
import 'package:korean_language_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:korean_language_app/features/books/data/models/book_item.dart';
part 'korean_books_state.dart';

class KoreanBooksCubit extends Cubit<KoreanBooksState> {
  final KoreanBookRepository repository;
  final AuthCubit authCubit;
  final AdminPermissionService adminService;
  
  int _currentPage = 0;
  static const int _pageSize = 5;
  
  KoreanBooksCubit({
    required this.repository,
    required this.authCubit,
    required this.adminService,
  }) : super(const KoreanBooksState());

  Future<void> loadInitialBooks() async {
    if (state.books.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }
    
    final result = await repository.getBooks(
      CourseCategory.korean,
      page: 0,
      pageSize: _pageSize
    );

    result.fold(
      onSuccess: (books) {
        _currentPage = books.length ~/ _pageSize;
        emit(state.copyWith(
          books: books,
          hasMore: true,
          isLoading: false,
          error: null,
          errorType: null,
        ));
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          isLoading: false,
          error: message,
          errorType: type,
        ));
      },
    );
  }

  Future<void> loadMoreBooks() async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    
    final result = await repository.getBooks(
      CourseCategory.korean,
      page: _currentPage + 1,
      pageSize: _pageSize
    );

    result.fold(
      onSuccess: (moreBooks) {
        final existingIds = state.books.map((book) => book.id).toSet();
        final uniqueNewBooks = moreBooks.where((book) => !existingIds.contains(book.id)).toList();
        
        if (uniqueNewBooks.isNotEmpty) {
          final allBooks = [...state.books, ...uniqueNewBooks];
          _currentPage = allBooks.length ~/ _pageSize;
          
          emit(state.copyWith(
            books: allBooks,
            hasMore: true,
            isLoadingMore: false,
            error: null,
            errorType: null,
          ));
        } else {
          emit(state.copyWith(
            hasMore: false,
            isLoadingMore: false,
            error: null,
            errorType: null,
          ));
        }
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          isLoadingMore: false,
          error: message,
          errorType: type,
        ));
      },
    );
  }

  Future<void> hardRefresh() async {
    emit(state.copyWith(isLoading: true));
    
    final result = await repository.hardRefreshBooks(
      CourseCategory.korean,
      pageSize: _pageSize
    );

    result.fold(
      onSuccess: (books) {
        _currentPage = books.length ~/ _pageSize;
        emit(state.copyWith(
          books: books,
          hasMore: true,
          isLoading: false,
          error: null,
          errorType: null,
        ));
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          isLoading: false,
          error: message,
          errorType: type,
        ));
      },
    );
  }

  Future<void> searchBooks(String query) async {
    if (query.trim().length < 2) return;
    
    emit(state.copyWith(isLoading: true));
    
    final result = await repository.searchBooks(CourseCategory.korean, query);

    result.fold(
      onSuccess: (books) {
        emit(state.copyWith(
          books: books,
          hasMore: false,
          isLoading: false,
          error: null,
          errorType: null,
        ));
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          isLoading: false,
          error: message,
          errorType: type,
        ));
      },
    );
  }

  Future<void> loadBookPdf(String bookId) async {
    if (state.pdfLoadingBookId == bookId) return;
    
    emit(state.copyWith(
      pdfLoadingBookId: bookId,
      loadedPdfFile: null,
      error: null,
      errorType: null,
    ));
    
    final result = await repository.getBookPdf(bookId);

    result.fold(
      onSuccess: (file) {
        if (file != null) {
          emit(state.copyWith(
            loadedPdfFile: file,
            pdfLoadingBookId: null,
            error: null,
            errorType: null,
          ));
        } else {
          emit(state.copyWith(
            pdfLoadingBookId: null,
            error: 'Failed to load PDF file',
            errorType: FailureType.notFound,
          ));
        }
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          pdfLoadingBookId: null,
          error: message,
          errorType: type,
        ));
      },
    );
  }

  Future<void> addBookToState(BookItem book) async {
    emit(state.copyWith(
      books: [book, ...state.books],
      error: null,
      errorType: null,
    ));
  }
  
  Future<void> updateBookInState(BookItem updatedBook) async {
    final bookIndex = state.books.indexWhere((b) => b.id == updatedBook.id);
    
    if (bookIndex != -1) {
      final updatedBooks = List<BookItem>.from(state.books);
      updatedBooks[bookIndex] = updatedBook;
      emit(state.copyWith(
        books: updatedBooks,
        error: null,
        errorType: null,
      ));
    }
  }

  Future<void> removeBookFromState(String bookId) async {
    final updatedBooks = state.books.where((b) => b.id != bookId).toList();
    emit(state.copyWith(
      books: updatedBooks,
      error: null,
      errorType: null,
    ));
  }
  
  Future<bool> canUserEditBook(String bookId) async {
    final user = _getCurrentUser();
    if (user == null) return false;
    
    // Check if user is admin
    if (await adminService.isUserAdmin(user.uid)) {
      return true;
    }
    
    // Check if user is book creator
    final book = state.books.firstWhere(
      (b) => b.id == bookId,
      orElse: () => const BookItem(
        id: '', title: '', description: '', 
        duration: '', chaptersCount: 0, icon: Icons.book,
        level: BookLevel.beginner, courseCategory: CourseCategory.korean,
        country: '', category: ''
      ),
    );
    
    return book.id.isNotEmpty && book.creatorUid == user.uid;
  }
  
  Future<bool> canUserDeleteBook(String bookId) async {
    return canUserEditBook(bookId);
  }
  
  Future<void> regenerateBookImageUrl(BookItem book) async {
    if (book.bookImagePath == null || book.bookImagePath!.isEmpty) {
      return;
    }
    
    final result = await repository.regenerateImageUrl(book);
    
    result.fold(
      onSuccess: (newUrl) {
        if (newUrl != null) {
          final updatedBook = book.copyWith(bookImage: newUrl);
          updateBookInState(updatedBook);
        }
      },
      onFailure: (message, type) {
        emit(state.copyWith(
          error: message,
          errorType: type,
        ));
      },
    );
  }
  
  UserEntity? _getCurrentUser() {
    final authState = authCubit.state;
    if (authState is Authenticated) {
      return authState.user;
    }
    return null;
  }
}