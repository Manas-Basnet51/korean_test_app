import 'dart:developer' as dev;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  bool _isConnected = true;
  final Set<String> _downloadsInProgress = {};
  
  KoreanBooksState? _cachedState;
  KoreanBooksState? get cachedState => _cachedState;
  
  KoreanBooksCubit({
    required this.repository,
    required this.authCubit,
    required this.adminService,
  }) : super(const KoreanBooksInitial()) {
    Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      if (_isConnected && state.books.isEmpty) {
        loadInitialBooks();
      }
    });
  }
  
  Future<void> loadInitialBooks() async {
    try {
      if (_cachedState == null || _cachedState!.books.isEmpty) {
        emit(state.copyWith(
          isLoading: true,
          currentOperation: const KoreanBooksOperation(
            type: KoreanBooksOperationType.loadBooks,
            status: KoreanBooksOperationStatus.inProgress,
          ),
        ));
      }
      
      final result = await repository.getBooks(
        CourseCategory.korean,
        page: 0,
        pageSize: _pageSize
      );
      
      result.fold(
        onSuccess: (books) async {
          final hasMoreResult = await repository.hasMoreBooks(
            CourseCategory.korean,
            books.length
          );

          _currentPage = books.length ~/ _pageSize;
          final uniqueBooks = _removeDuplicates(books);
          
          final newState = KoreanBooksState(
            books: uniqueBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const KoreanBooksOperation(
              type: KoreanBooksOperationType.loadBooks,
              status: KoreanBooksOperationStatus.completed,
            ),
          );
          
          _cachedState = newState;
          emit(newState);
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          if (_cachedState != null && _cachedState!.books.isNotEmpty) {
            emit(_cachedState!.copyWithBaseState(error: message, errorType: type));
            Future.delayed(const Duration(milliseconds: 100), () {
              emit(_cachedState!);
            });
          } else {
            emit(state.copyWithBaseState(
              error: message,
              errorType: type,
              isLoading: false,
            ).copyWithOperation(const KoreanBooksOperation(
              type: KoreanBooksOperationType.loadBooks,
              status: KoreanBooksOperationStatus.failed,
            )));
          }
        },
      );
    } catch (e) {
      dev.log('Error loading initial books: $e');
      _handleError('Failed to load books: $e', KoreanBooksOperationType.loadBooks);
    }
  }
  
  Future<void> loadMoreBooks() async {    
    if (!state.hasMore || !_isConnected || state.currentOperation.isInProgress) {
      return;
    }
    
    try {
      emit(state.copyWith(
        currentOperation: const KoreanBooksOperation(
          type: KoreanBooksOperationType.loadMoreBooks,
          status: KoreanBooksOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.getBooks(
        CourseCategory.korean,
        page: _currentPage + 1,
        pageSize: _pageSize
      );
      
      result.fold(
        onSuccess: (moreBooks) async {
          final existingIds = state.books.map((book) => book.id).toSet();
          final uniqueNewBooks = moreBooks.where((book) => !existingIds.contains(book.id)).toList();
          
          if (uniqueNewBooks.isNotEmpty) {
            final allBooks = [...state.books, ...uniqueNewBooks];
            final hasMoreResult = await repository.hasMoreBooks(CourseCategory.korean, allBooks.length);
            
            _currentPage = allBooks.length ~/ _pageSize;
            
            final newState = state.copyWith(
              books: allBooks,
              hasMore: hasMoreResult.fold(
                onSuccess: (hasMore) => hasMore,
                onFailure: (_, __) => false,
              ),
              currentOperation: const KoreanBooksOperation(
                type: KoreanBooksOperationType.loadMoreBooks,
                status: KoreanBooksOperationStatus.completed,
              ),
            );
            
            _cachedState = newState;
            emit(newState);
          } else {
            emit(state.copyWith(
              hasMore: false,
              currentOperation: const KoreanBooksOperation(
                type: KoreanBooksOperationType.loadMoreBooks,
                status: KoreanBooksOperationStatus.completed,
              ),
            ));
          }
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          emit(state.copyWithBaseState(error: message, errorType: type));
          Future.delayed(const Duration(milliseconds: 100), () {
            emit(state.copyWithOperation(const KoreanBooksOperation(
              type: KoreanBooksOperationType.loadMoreBooks,
              status: KoreanBooksOperationStatus.failed,
            )));
          });
        },
      );
    } catch (e) {
      dev.log('Error loading more books: $e');
      _handleError('Failed to load more books: $e', KoreanBooksOperationType.loadMoreBooks);
    }
  }
  
  Future<void> hardRefresh() async {
    try {
      emit(state.copyWith(
        isLoading: true,
        currentOperation: const KoreanBooksOperation(
          type: KoreanBooksOperationType.refreshBooks,
          status: KoreanBooksOperationStatus.inProgress,
        ),
      ));
      
      _currentPage = 0;
      final result = await repository.hardRefreshBooks(
        CourseCategory.korean,
        pageSize: _pageSize
      );
      
      result.fold(
        onSuccess: (books) async {
          final uniqueBooks = _removeDuplicates(books);
          final hasMoreResult = await repository.hasMoreBooks(CourseCategory.korean, uniqueBooks.length);
          
          _currentPage = uniqueBooks.length ~/ _pageSize;
          
          final newState = KoreanBooksState(
            books: uniqueBooks,
            hasMore: hasMoreResult.fold(
              onSuccess: (hasMore) => hasMore,
              onFailure: (_, __) => false,
            ),
            currentOperation: const KoreanBooksOperation(
              type: KoreanBooksOperationType.refreshBooks,
              status: KoreanBooksOperationStatus.completed,
            ),
          );
          
          _cachedState = newState;
          emit(newState);
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          if (_cachedState != null && _cachedState!.books.isNotEmpty) {
            emit(_cachedState!.copyWithBaseState(error: message, errorType: type));
            Future.delayed(const Duration(milliseconds: 100), () {
              emit(_cachedState!);
            });
          } else {
            emit(state.copyWithBaseState(
              error: message,
              errorType: type,
              isLoading: false,
            ).copyWithOperation(const KoreanBooksOperation(
              type: KoreanBooksOperationType.refreshBooks,
              status: KoreanBooksOperationStatus.failed,
            )));
          }
        },
      );
    } catch (e) {
      dev.log('Error refreshing books: $e');
      _handleError('Failed to refresh books: $e', KoreanBooksOperationType.refreshBooks);
    }
  }
  
  Future<void> searchBooks(String query) async {
    if (query.trim().length < 2) {
      return;
    }
    
    try {
      emit(state.copyWith(
        isLoading: true,
        currentOperation: const KoreanBooksOperation(
          type: KoreanBooksOperationType.searchBooks,
          status: KoreanBooksOperationStatus.inProgress,
        ),
      ));
      
      final result = await repository.searchBooks(CourseCategory.korean, query);
      
      result.fold(
        onSuccess: (searchResults) {
          final uniqueSearchResults = _removeDuplicates(searchResults);
          
          final newState = state.copyWith(
            books: uniqueSearchResults,
            hasMore: false,
            isLoading: false,
            currentOperation: const KoreanBooksOperation(
              type: KoreanBooksOperationType.searchBooks,
              status: KoreanBooksOperationStatus.completed,
            ),
          );
          
          emit(newState);
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          if (_cachedState != null && _cachedState!.books.isNotEmpty) {
            emit(_cachedState!.copyWithBaseState(error: message, errorType: type));
            Future.delayed(const Duration(milliseconds: 100), () {
              emit(_cachedState!);
            });
          } else {
            emit(state.copyWithBaseState(
              error: message,
              errorType: type,
              isLoading: false,
            ).copyWithOperation(const KoreanBooksOperation(
              type: KoreanBooksOperationType.searchBooks,
              status: KoreanBooksOperationStatus.failed,
            )));
          }
        },
      );
    } catch (e) {
      dev.log('Error searching books: $e');
      _handleError('Failed to search books: $e', KoreanBooksOperationType.searchBooks);
    }
  }
  
  Future<void> loadBookPdf(String bookId) async {
    if (_downloadsInProgress.contains(bookId)) {
      return;
    }
    
    try {
      _downloadsInProgress.add(bookId);
      
      emit(state.copyWith(
        currentOperation: KoreanBooksOperation(
          type: KoreanBooksOperationType.loadPdf,
          status: KoreanBooksOperationStatus.inProgress,
          bookId: bookId,
        ),
      ));
      
      final result = await repository.getBookPdf(bookId);
      
      result.fold(
        onSuccess: (pdfFile) {
          if (pdfFile != null) {
            emit(state.copyWith(
              loadedPdfFile: pdfFile,
              loadedPdfBookId: bookId,
              currentOperation: KoreanBooksOperation(
                type: KoreanBooksOperationType.loadPdf,
                status: KoreanBooksOperationStatus.completed,
                bookId: bookId,
              ),
            ));
          } else {
            emit(state.copyWith(
              currentOperation: KoreanBooksOperation(
                type: KoreanBooksOperationType.loadPdf,
                status: KoreanBooksOperationStatus.failed,
                bookId: bookId,
                message: 'PDF file is empty or corrupted',
              ),
            ));
          }
          _clearOperationAfterDelay();
        },
        onFailure: (message, type) {
          emit(state.copyWith(
            currentOperation: KoreanBooksOperation(
              type: KoreanBooksOperationType.loadPdf,
              status: KoreanBooksOperationStatus.failed,
              bookId: bookId,
              message: message,
            ),
          ));
          _clearOperationAfterDelay();
        },
      );
    } catch (e) {
      dev.log('Error loading PDF: $e');
      emit(state.copyWith(
        currentOperation: KoreanBooksOperation(
          type: KoreanBooksOperationType.loadPdf,
          status: KoreanBooksOperationStatus.failed,
          bookId: bookId,
          message: 'Failed to load PDF: $e',
        ),
      ));
      _clearOperationAfterDelay();
    } finally {
      _downloadsInProgress.remove(bookId);
    }
  }
  
  Future<void> addBookToState(BookItem book) async {
    try {
      final hasMoreResult = await repository.hasMoreBooks(CourseCategory.korean, state.books.length + 1);
      
      final newState = state.copyWith(
        books: [book, ...state.books],
        hasMore: hasMoreResult.fold(
          onSuccess: (hasMore) => hasMore,
          onFailure: (_, __) => state.hasMore,
        ),
      );
      
      _cachedState = newState;
      emit(newState);
    } catch (e) {
      dev.log('Error adding book to state: $e');
    }
  }
  
  Future<void> updateBookInState(BookItem updatedBook) async {
    try {
      final bookIndex = state.books.indexWhere((b) => b.id == updatedBook.id);
      
      if (bookIndex != -1) {
        final updatedBooks = List<BookItem>.from(state.books);
        updatedBooks[bookIndex] = updatedBook;
        
        final newState = state.copyWith(books: updatedBooks);
        _cachedState = newState;
        emit(newState);
      }
    } catch (e) {
      dev.log('Error updating book in state: $e');
    }
  }

  Future<void> removeBookFromState(String bookId) async {
    try {
      final updatedBooks = state.books.where((b) => b.id != bookId).toList();
      
      final newState = state.copyWith(books: updatedBooks);
      _cachedState = newState;
      emit(newState);
    } catch (e) {
      dev.log('Error removing book from state: $e');
    }
  }
  
  Future<bool> canUserEditBook(String bookId) async {
    try {
      final UserEntity? user = _getCurrentUser();
      if (user == null) {
        return false;
      }
      
      if (await adminService.isUserAdmin(user.uid)) {
        return true;
      }
      
      final book = state.books.firstWhere(
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
    } catch (e) {
      dev.log('Error checking edit permission: $e');
      return false;
    }
  }
  
  Future<bool> canUserDeleteBook(String bookId) async {
    return canUserEditBook(bookId);
  }
  
  Future<void> regenerateBookImageUrl(BookItem book) async {
    if (book.bookImagePath == null || book.bookImagePath!.isEmpty) {
      return;
    }
    
    try {
      final result = await repository.regenerateImageUrl(book);
      
      result.fold(
        onSuccess: (newImageUrl) {
          if (newImageUrl != null) {
            final bookIndex = state.books.indexWhere((b) => b.id == book.id);
            if (bookIndex == -1) return;
            
            final updatedBook = book.copyWith(bookImage: newImageUrl);
            final updatedBooks = List<BookItem>.from(state.books);
            updatedBooks[bookIndex] = updatedBook;

            final newState = state.copyWith(books: updatedBooks);
            _cachedState = newState;
            emit(newState);
          }
        },
        onFailure: (message, type) {
          dev.log('Failed to regenerate book image URL: $message');
        },
      );
    } catch (e) {
      dev.log('Error regenerating book image URL: $e');
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

  void _handleError(String message, KoreanBooksOperationType operationType) {
    if (_cachedState != null && _cachedState!.books.isNotEmpty) {
      emit(_cachedState!.copyWithBaseState(error: message));
      Future.delayed(const Duration(milliseconds: 100), () {
        emit(_cachedState!.copyWithOperation(KoreanBooksOperation(
          type: operationType,
          status: KoreanBooksOperationStatus.failed,
          message: message,
        )));
      });
    } else {
      emit(state.copyWithBaseState(
        error: message,
        isLoading: false,
      ).copyWithOperation(KoreanBooksOperation(
        type: operationType,
        status: KoreanBooksOperationStatus.failed,
        message: message,
      )));
    }
    
    _clearOperationAfterDelay();
  }

  void _clearOperationAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (state.currentOperation.status != KoreanBooksOperationStatus.none) {
        emit(state.copyWithOperation(const KoreanBooksOperation(status: KoreanBooksOperationStatus.none)));
      }
    });
  }
}