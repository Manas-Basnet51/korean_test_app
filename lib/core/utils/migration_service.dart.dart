import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class TestResultsMigrationService {
  final FirebaseFirestore firestore;
  final String oldCollection = 'test_results';
  final String usersCollection = 'users';
  final String userResultsSubcollection = 'test_results';
  
  // Stream controller for progress updates
  final StreamController<MigrationProgress> _progressController = StreamController<MigrationProgress>();
  Stream<MigrationProgress> get progressStream => _progressController.stream;

  TestResultsMigrationService({required this.firestore});

  /// Get migration status and statistics
  Future<MigrationStatus> getMigrationStatus() async {
    try {
      // Count documents in old collection
      final oldCollectionSnapshot = await firestore
          .collection(oldCollection)
          .count()
          .get();
      final oldCount = oldCollectionSnapshot.count!;
      
      if (oldCount == 0) {
        return MigrationStatus(
          oldCollectionCount: 0,
          newCollectionCount: 0,
          isCompleted: true,
          canStartMigration: false,
        );
      }
      
      // Count documents in subcollections (sample a few users)
      final userDocsSnapshot = await firestore
          .collection(usersCollection)
          .limit(10)
          .get();
      
      int newCount = 0;
      for (final userDoc in userDocsSnapshot.docs) {
        final userResultsSnapshot = await firestore
            .collection(usersCollection)
            .doc(userDoc.id)
            .collection(userResultsSubcollection)
            .count()
            .get();
        newCount += userResultsSnapshot.count!;
      }
      
      return MigrationStatus(
        oldCollectionCount: oldCount,
        newCollectionCount: newCount,
        isCompleted: oldCount == newCount && newCount > 0,
        canStartMigration: oldCount > 0,
      );
      
    } catch (e) {
      throw Exception('Failed to get migration status: $e');
    }
  }

  /// Start the migration process
  Future<MigrationResult> startMigration() async {
    try {
      _progressController.add(MigrationProgress(
        status: 'Starting migration...',
        processedCount: 0,
        totalCount: null,
        isCompleted: false,
      ));
      
      int totalMigrated = 0;
      int totalErrors = 0;
      List<String> errorMessages = [];
      
      // Get total count first
      final totalSnapshot = await firestore.collection(oldCollection).count().get();
      final totalCount = totalSnapshot.count!;
      
      _progressController.add(MigrationProgress(
        status: 'Found $totalCount documents to migrate',
        processedCount: 0,
        totalCount: totalCount,
        isCompleted: false,
      ));
      
      // Process in batches
      Query query = firestore.collection(oldCollection);
      DocumentSnapshot? lastDoc;
      
      do {
        Query batchQuery = query.limit(100); // Smaller batches for UI responsiveness
        if (lastDoc != null) {
          batchQuery = batchQuery.startAfterDocument(lastDoc);
        }
        
        final snapshot = await batchQuery.get();
        if (snapshot.docs.isEmpty) break;
        
        // Process this batch
        final batchResult = await _migrateBatch(snapshot.docs);
        totalMigrated += batchResult.migrated;
        totalErrors += batchResult.errors;
        errorMessages.addAll(batchResult.errorMessages);
        
        lastDoc = snapshot.docs.last;
        
        // Update progress
        _progressController.add(MigrationProgress(
          status: 'Migrated $totalMigrated of $totalCount documents',
          processedCount: totalMigrated + totalErrors,
          totalCount: totalCount,
          isCompleted: false,
        ));
        
        // Small delay for UI responsiveness
        await Future.delayed(const Duration(milliseconds: 50));
        
      } while (true);
      
      final result = MigrationResult(
        migrated: totalMigrated,
        errors: totalErrors,
        errorMessages: errorMessages,
      );
      
      _progressController.add(MigrationProgress(
        status: 'Migration completed: ${result.migrated} migrated, ${result.errors} errors',
        processedCount: totalMigrated + totalErrors,
        totalCount: totalCount,
        isCompleted: true,
      ));
      
      return result;
      
    } catch (e) {
      _progressController.add(MigrationProgress(
        status: 'Migration failed: $e',
        processedCount: 0,
        totalCount: null,
        isCompleted: true,
        hasError: true,
      ));
      throw Exception('Migration failed: $e');
    }
  }
  
  /// Migrate a batch of documents
  Future<MigrationResult> _migrateBatch(List<QueryDocumentSnapshot> docs) async {
    int migrated = 0;
    int errors = 0;
    List<String> errorMessages = [];
    
    WriteBatch batch = firestore.batch();
    int operationsInBatch = 0;
    
    for (final doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String?;
        
        if (userId == null || userId.isEmpty) {
          errors++;
          errorMessages.add('Document ${doc.id} missing userId');
          continue;
        }
        
        // Prepare data for subcollection (remove userId)
        final subcollectionData = Map<String, dynamic>.from(data);
        subcollectionData.remove('userId');
        
        // Add to user's subcollection
        final userResultRef = firestore
            .collection(usersCollection)
            .doc(userId)
            .collection(userResultsSubcollection)
            .doc(doc.id); // Keep same document ID
        
        batch.set(userResultRef, subcollectionData);
        operationsInBatch++;
        
        // Commit batch if it's getting full
        if (operationsInBatch >= 450) {
          await batch.commit();
          migrated += operationsInBatch;
          batch = firestore.batch();
          operationsInBatch = 0;
        }
        
      } catch (e) {
        errors++;
        errorMessages.add('Error processing document ${doc.id}: $e');
      }
    }
    
    // Commit remaining operations
    if (operationsInBatch > 0) {
      try {
        await batch.commit();
        migrated += operationsInBatch;
      } catch (e) {
        errors += operationsInBatch;
        errorMessages.add('Final batch commit failed: $e');
      }
    }
    
    return MigrationResult(
      migrated: migrated,
      errors: errors,
      errorMessages: errorMessages,
    );
  }
  
  /// Verify migration by comparing counts
  Future<bool> verifyMigration() async {
    try {
      final status = await getMigrationStatus();
      return status.isCompleted && status.oldCollectionCount == status.newCollectionCount;
    } catch (e) {
      return false;
    }
  }
  
  /// Delete old collection after successful migration
  Future<MigrationResult> deleteOldCollection() async {
    try {
      _progressController.add(MigrationProgress(
        status: 'Starting deletion of old collection...',
        processedCount: 0,
        totalCount: null,
        isCompleted: false,
      ));
      
      int deletedCount = 0;
      Query query = firestore.collection(oldCollection);
      
      do {
        final snapshot = await query.limit(100).get();
        if (snapshot.docs.isEmpty) break;
        
        // Delete in batches
        WriteBatch batch = firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        deletedCount += snapshot.docs.length;
        
        _progressController.add(MigrationProgress(
          status: 'Deleted $deletedCount documents from old collection',
          processedCount: deletedCount,
          totalCount: null,
          isCompleted: false,
        ));
        
        // Small delay
        await Future.delayed(const Duration(milliseconds: 50));
        
      } while (true);
      
      _progressController.add(MigrationProgress(
        status: 'Successfully deleted $deletedCount documents',
        processedCount: deletedCount,
        totalCount: deletedCount,
        isCompleted: true,
      ));
      
      return MigrationResult(
        migrated: deletedCount,
        errors: 0,
        errorMessages: [],
      );
      
    } catch (e) {
      _progressController.add(MigrationProgress(
        status: 'Failed to delete old collection: $e',
        processedCount: 0,
        totalCount: null,
        isCompleted: true,
        hasError: true,
      ));
      throw Exception('Failed to delete old collection: $e');
    }
  }
  
  void dispose() {
    _progressController.close();
  }
}

class MigrationStatus {
  final int oldCollectionCount;
  final int newCollectionCount;
  final bool isCompleted;
  final bool canStartMigration;
  
  MigrationStatus({
    required this.oldCollectionCount,
    required this.newCollectionCount,
    required this.isCompleted,
    required this.canStartMigration,
  });
}

class MigrationProgress {
  final String status;
  final int processedCount;
  final int? totalCount;
  final bool isCompleted;
  final bool hasError;
  
  MigrationProgress({
    required this.status,
    required this.processedCount,
    required this.totalCount,
    required this.isCompleted,
    this.hasError = false,
  });
  
  double? get progressPercentage {
    if (totalCount == null || totalCount == 0) return null;
    return (processedCount / totalCount!) * 100;
  }
}

class MigrationResult {
  final int migrated;
  final int errors;
  final List<String> errorMessages;
  
  MigrationResult({
    required this.migrated,
    required this.errors,
    required this.errorMessages,
  });
  
  bool get isSuccessful => errors == 0;
  
  @override
  String toString() {
    return 'Migration Result: $migrated migrated, $errors errors';
  }
}