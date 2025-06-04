class TestCacheHealthStatus {
  final bool isValid;
  final int testsCount;
  final int resultsCount;
  final bool hasCorruptedEntries;
  final DateTime? lastSyncTime;

  TestCacheHealthStatus({
    required this.isValid,
    required this.testsCount,
    required this.resultsCount,
    required this.hasCorruptedEntries,
    this.lastSyncTime,
  });

  bool get isHealthy => isValid && !hasCorruptedEntries && testsCount >= 0;
  
  @override
  String toString() {
    return 'TestCacheHealthStatus(isValid: $isValid, testsCount: $testsCount, resultsCount: $resultsCount, hasCorruptedEntries: $hasCorruptedEntries, lastSyncTime: $lastSyncTime)';
  }
}