import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:korean_language_app/core/utils/migration_service.dart.dart';

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  late TestResultsMigrationService migrationService;
  MigrationStatus? migrationStatus;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    migrationService = TestResultsMigrationService(
      firestore: FirebaseFirestore.instance,
    );
    _loadMigrationStatus();
  }
  
  Future<void> _loadMigrationStatus() async {
    setState(() => isLoading = true);
    try {
      final status = await migrationService.getMigrationStatus();
      setState(() => migrationStatus = status);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  Future<void> _startMigration() async {
    // Show progress dialog and start migration
    // showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) => MigrationProgressDialog(
    //     migrationService: migrationService,
    //   ),
    // );
    
    try {
      await migrationService.startMigration();
      // Refresh status after migration
      await _loadMigrationStatus();
    } catch (e) {
      // Handle error
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Migration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (migrationStatus != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Old Collection: ${migrationStatus!.oldCollectionCount} documents'),
                      Text('New Collection: ${migrationStatus!.newCollectionCount} documents'),
                      const SizedBox(height: 16),
                      if (migrationStatus!.canStartMigration)
                        ElevatedButton(
                          onPressed: _startMigration,
                          child: const Text('Start Migration'),
                        ),
                      if (migrationStatus!.isCompleted)
                        ElevatedButton(
                          onPressed: () async {
                            await migrationService.deleteOldCollection();
                            await _loadMigrationStatus();
                          },
                          child: const Text('Delete Old Collection'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    migrationService.dispose();
    super.dispose();
  }
}