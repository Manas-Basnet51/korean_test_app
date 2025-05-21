import 'dart:developer' as dev;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:korean_language_app/core/enums/book_level.dart';
import 'package:korean_language_app/core/enums/course_category.dart';
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
  bool _isConnected = true;
  final Set<String> _downloadsInProgress = {};
  
  KoreanBooksCubit({
    required this.repository,
    required this.authCubit,
    required this.adminService,
  }) : super(KoreanBooksInitial()) {
    Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      if (_isConnected && state is KoreanBooksLoaded && 
          (state as KoreanBooksLoaded).books.isEmpty) {
        loadInitialBooks();
      }
    });
  }
  
  Future<void> loadInitialBooks() async {
    if (state is! KoreanBooksLoaded) {
      emit(KoreanBooksLoading());
    }
    
    try {
      List<BookItem> books = await repository.getBooks(
        CourseCategory.korean,
        page: 0,
        pageSize: _pageSize
      );
      
      bool hasMoreBooks = await repository.hasMoreBooks(
        CourseCategory.korean,
        books.length
      );

      _currentPage = books.length ~/ _pageSize;
      final uniqueBooks = _removeDuplicates(books);
      
      emit(KoreanBooksLoaded(uniqueBooks, hasMoreBooks));
    } catch (e) {
      emit(KoreanBooksError('Failed to load books: $e'));
    }
  }
  
  Future<void> loadMoreBooks() async {
    final currentState = state;
    
    if (currentState is KoreanBooksLoaded && currentState.hasMore && _isConnected) {
      emit(KoreanBooksLoadingMore(currentState.books));
      
      try {
        final moreBooks = await repository.getBooks(
          CourseCategory.korean,
          page: _currentPage + 1,
          pageSize: _pageSize
        );
        
        final existingIds = currentState.books.map((book) => book.id).toSet();
        final uniqueNewBooks = moreBooks.where((book) => !existingIds.contains(book.id)).toList();
        
        if (uniqueNewBooks.isNotEmpty) {
          final allBooks = [...currentState.books, ...uniqueNewBooks];
          final hasMore = await repository.hasMoreBooks(CourseCategory.korean, allBooks.length);
          
          _currentPage = allBooks.length ~/ _pageSize;
          
          emit(KoreanBooksLoaded(allBooks, hasMore));
        } else {
          emit(KoreanBooksLoaded(currentState.books, false));
        }
      } catch (e) {
        emit(KoreanBooksLoaded(currentState.books, currentState.hasMore));
      }
    }
  }
  
  Future<void> hardRefresh() async {
    if (!_isConnected) {
      return loadInitialBooks();
    }
    
    List<BookItem> currentBooks = state is KoreanBooksLoaded ? (state as KoreanBooksLoaded).books : [];
    
    emit(KoreanBooksLoading());
    
    try {
      _currentPage = 0;
      final books = await repository.hardRefreshBooks(
        CourseCategory.korean,
        pageSize: _pageSize
      );
      
      final uniqueBooks = _removeDuplicates(books);
      final hasMore = await repository.hasMoreBooks(CourseCategory.korean, uniqueBooks.length);
      
      _currentPage = uniqueBooks.length ~/ _pageSize;
      
      emit(KoreanBooksLoaded(uniqueBooks, hasMore));
    } catch (e) {
      if (currentBooks.isNotEmpty) {
        emit(KoreanBooksLoaded(currentBooks, true));
      } else {
        emit(KoreanBooksError('Failed to refresh books: $e'));
      }
    }
  }
  
  Future<void> searchBooks(String query) async {
    if (query.trim().length < 2) {
      return;
    }
    
    List<BookItem> currentBooks = state is KoreanBooksLoaded ? (state as KoreanBooksLoaded).books : [];
    final hasMore = state is KoreanBooksLoaded ? (state as KoreanBooksLoaded).hasMore : false;
    
    emit(KoreanBooksLoading());
    
    try {
      final searchResults = await repository.searchBooks(CourseCategory.korean, query);
      final uniqueSearchResults = _removeDuplicates(searchResults);
      
      emit(KoreanBooksLoaded(uniqueSearchResults, false));
    } catch (e) {
      if (currentBooks.isNotEmpty) {
        emit(KoreanBooksLoaded(currentBooks, hasMore));
      } else {
        emit(KoreanBooksError('Failed to search books: $e'));
      }
    }
  }
  
  Future<void> loadBookPdf(String bookId) async {
    if (_downloadsInProgress.contains(bookId)) {
      return;
    }
    
    final currentState = state;
    if (currentState is! KoreanBooksLoaded && 
        currentState is! KoreanBooksLoadingMore && 
        currentState is! KoreanBookPdfLoaded && 
        currentState is! KoreanBookPdfError) {
      return;
    }
    
    List<BookItem> books = [];
    bool hasMore = false;
    
    if (currentState is KoreanBooksLoaded) {
      books = currentState.books;
      hasMore = currentState.hasMore;
    } else if (currentState is KoreanBooksLoadingMore) {
      books = currentState.currentBooks;
      hasMore = true;
    } else if (currentState is KoreanBookPdfLoaded) {
      books = currentState.books;
      hasMore = currentState.hasMore;
    } else if (currentState is KoreanBookPdfError) {
      books = currentState.books;
      hasMore = currentState.hasMore;
    }
    
    final bookIndex = books.indexWhere((book) => book.id == bookId);
    if (bookIndex == -1) {
      emit(KoreanBookPdfError(bookId, 'Book not found', books, hasMore));
      return;
    }
    
    _downloadsInProgress.add(bookId);
    
    try {
      emit(KoreanBookPdfLoading(bookId, books, hasMore));
      
      final pdfFile = await repository.getBookPdf(bookId);
      
      if (pdfFile != null && await pdfFile.exists() && await pdfFile.length() > 0) {
        emit(KoreanBookPdfLoaded(bookId, pdfFile, books, hasMore));
      } else {
        emit(KoreanBookPdfError(bookId, 'PDF file is empty or corrupted', books, hasMore));
      }
    } catch (e) {
      emit(KoreanBookPdfError(bookId, 'Failed to load PDF: $e', books, hasMore));
    } finally {
      _downloadsInProgress.remove(bookId);
    }
  }
  
  Future<void> addBookToState(BookItem book) async {
    if (state is KoreanBooksLoaded) {
      final currentState = state as KoreanBooksLoaded;
      final updatedBooks = [book, ...currentState.books];
      final hasMore = await repository.hasMoreBooks(CourseCategory.korean, updatedBooks.length);
      emit(KoreanBooksLoaded(updatedBooks, hasMore));
    }
  }
  
  Future<void> updateBookInState(BookItem updatedBook) async {
    if (state is KoreanBooksLoaded) {
      final currentState = state as KoreanBooksLoaded;
      final bookIndex = currentState.books.indexWhere((b) => b.id == updatedBook.id);
      
      if (bookIndex != -1) {
        final updatedBooks = List<BookItem>.from(currentState.books);
        updatedBooks[bookIndex] = updatedBook;
        emit(KoreanBooksLoaded(updatedBooks, currentState.hasMore));
      }
    }
  }

  Future<void> removeBookFromState(String bookId) async {
    if (state is KoreanBooksLoaded) {
      final currentState = state as KoreanBooksLoaded;
      final updatedBooks = currentState.books.where((b) => b.id != bookId).toList();
      emit(KoreanBooksLoaded(updatedBooks, currentState.hasMore));
    }
  }
  
  Future<bool> canUserEditBook(String bookId) async {
    final UserEntity? user = _getCurrentUser();
    if (user == null) {
      return false;
    }
    
    // Check if user is admin
    if (await adminService.isUserAdmin(user.uid)) {
      return true;
    }
    
    final List<BookItem> books = _getBooksFromCurrentState();
    
    //Check if use is book creator
    final book = books.firstWhere(
      (b) => b.id == bookId,
      orElse: () => const BookItem(
        id: '', title: '', description: '', 
        duration: '', chaptersCount: 0, icon: Icons.book,
        level: BookLevel.beginner, courseCategory: CourseCategory.korean,
        country: '', category: ''
      )
    );
    
    if (book.id.isNotEmpty && book.creatorUid == user.uid) {
      return true;
    }
    
    return false;
  }
  
  Future<bool> canUserDeleteBook(String bookId) async {
    // same permission check as edit
    return canUserEditBook(bookId);
  }
  
  Future<void> regenerateBookImageUrl(BookItem book) async {
    if (book.bookImagePath == null || book.bookImagePath!.isEmpty) {
      return;
    }
    
    try {
      final currentState = state;
      List<BookItem> currentBooks = [];
      bool hasMore = false;
      
      if (currentState is KoreanBooksLoaded) {
        currentBooks = currentState.books;
        hasMore = currentState.hasMore;
      } else if (currentState is KoreanBookPdfLoaded) {
        currentBooks = currentState.books;
        hasMore = currentState.hasMore;
      } else {
        return;
      }
      
      final newImageUrl = await repository.regenerateImageUrl(book);
      
      if (newImageUrl != null) {
        final bookIndex = currentBooks.indexWhere((b) => b.id == book.id);
        if (bookIndex == -1) return;
        
        final updatedBook = book.copyWith(bookImage: newImageUrl);
        final updatedBooks = List<BookItem>.from(currentBooks);
        updatedBooks[bookIndex] = updatedBook;

        if (currentState is KoreanBooksLoaded) {
          emit(KoreanBooksLoaded(updatedBooks, hasMore));
        } else if (currentState is KoreanBookPdfLoaded) {
          emit(KoreanBookPdfLoaded(
            currentState.bookId, 
            currentState.pdfFile, 
            updatedBooks, 
            hasMore
          ));
        }
      }
    } catch (e) {
      dev.log('Failed to regenerate book image URL: $e');
    }
  }
  
  UserEntity? _getCurrentUser() {
    final authState = authCubit.state;
    if (authState is Authenticated) {
      return authState.user;
    }
    return null;
  }
  
  List<BookItem> _removeDuplicates(List<BookItem> books) {
    final uniqueIds = <String>{};
    final uniqueBooks = <BookItem>[];
    
    for (final book in books) {
      if (uniqueIds.add(book.id)) {
        uniqueBooks.add(book);
      }
    }
    
    return uniqueBooks;
  }

  // Helper method to get books from any state that contains books
  List<BookItem> _getBooksFromCurrentState() {
    final currentState = state;
    
    if (currentState is KoreanBooksLoaded) {
      return currentState.books;
    } else if (currentState is KoreanBooksLoadingMore) {
      return currentState.currentBooks;
    } else if (currentState is KoreanBookPdfLoading) {
      return currentState.books;
    } else if (currentState is KoreanBookPdfLoaded) {
      return currentState.books;
    } else if (currentState is KoreanBookPdfError) {
      return currentState.books;
    }
    
    return [];
  }

}
