import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

abstract class AdminPermissionService {
  Future<bool> isUserAdmin(String userId);
  Future<void> registerAdmin(String userId, {Map<String, dynamic>? additionalData});
  Future<bool?> validateAdminCode(String code);
  void clearCache();
}

class FirebaseAdminPermissionService implements AdminPermissionService {
  final FirebaseFirestore _firestore;
  final String _adminCollectionPath = 'admin_users';
  final String _configCollectionPath = 'app_config';
  final String _adminConfigDocId = 'admin_settings';
  
  // Cache admin status to reduce Firestore reads
  final Map<String, bool> _adminCache = {};
  final Duration _cacheDuration = const Duration(minutes: 30);
  final Map<String, DateTime> _cacheTimestamps = {};
  
  FirebaseAdminPermissionService({required FirebaseFirestore firestore}) : _firestore = firestore;
  
  @override
  Future<bool> isUserAdmin(String userId) async {
    if (userId.isEmpty) return false;
    
    // Check cache first
    if (_isCacheValid(userId)) {
      return _adminCache[userId] ?? false;
    }
    
    try {
      final docSnapshot = await _firestore.collection(_adminCollectionPath).doc(userId).get();
      final isAdmin = docSnapshot.exists && (docSnapshot.data()?['isActive'] ?? true);
      
      // Update cache
      _updateCache(userId, isAdmin);
      return isAdmin;
    } catch (e) {
      if (kDebugMode) print('Error checking admin status: $e');
      return false;
    }
  }
  
  @override
  Future<void> registerAdmin(String userId, {Map<String, dynamic>? additionalData}) async {
    if (userId.isEmpty) throw Exception('User ID cannot be empty');
    
    try {
      final Map<String, dynamic> data = {
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
        ...?additionalData,
      };
      
      await _firestore.collection(_adminCollectionPath).doc(userId).set(data);
      _updateCache(userId, true);
      
    } catch (e) {
      if (kDebugMode) print('Error registering admin: $e');
      throw Exception('Failed to register admin: $e');
    }
  }
  
  @override
  Future<bool?> validateAdminCode(String code) async {
    try {
      // First try to get the code from Firestore
      final configDoc = await _firestore
          .collection(_configCollectionPath)
          .doc(_adminConfigDocId)
          .get();
      
      if (configDoc.exists) {
        final validCode = configDoc.data()?['adminSecretCode'];
        if (validCode != null) {
          return code == validCode;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Error validating admin code: $e');
      return null;
    }
  }
  
  @override
  void clearCache() {
    _adminCache.clear();
    _cacheTimestamps.clear();
  }
  
  bool _isCacheValid(String userId) {
    if (!_adminCache.containsKey(userId)) return false;
    
    final cacheTime = _cacheTimestamps[userId];
    return cacheTime != null && 
        DateTime.now().difference(cacheTime) < _cacheDuration;
  }
  
  void _updateCache(String userId, bool isAdmin) {
    _adminCache[userId] = isAdmin;
    _cacheTimestamps[userId] = DateTime.now();
  }
}