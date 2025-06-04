
class BookCacheHealthStatus {
  final bool isValid;
  final int bookCount;
  final bool hasCorruptedEntries;
  final DateTime? lastSyncTime;

  BookCacheHealthStatus({
    required this.isValid,
    required this.bookCount,
    required this.hasCorruptedEntries,
    this.lastSyncTime,
  });

  bool get isHealthy => isValid && !hasCorruptedEntries && bookCount > 0;
  
  @override
  String toString() {
    return 'BookCacheHealthStatus(isValid: $isValid, bookCount: $bookCount, hasCorruptedEntries: $hasCorruptedEntries, lastSyncTime: $lastSyncTime)';
  }
}