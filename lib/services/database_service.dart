import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth_service.dart';

/// DatabaseService - Simplified Local-First
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final AuthService _auth = AuthService();
  FirebaseFirestore? _firestore;
  final Map<String, Box> _boxes = {};
  bool _isInitialized = false;

  static const String _guestUserId = 'guest_user';

  // Track if initial sync is done (per collection)
  final Map<String, bool> _hasSyncedOnce = {};

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize({required List<String> boxes}) async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      for (String boxName in boxes) {
        _boxes[boxName] = await Hive.openBox(boxName);
        _hasSyncedOnce[boxName] = false;
      }

      _firestore = FirebaseFirestore.instance;
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _isInitialized = true;
      print('✅ Database initialized with boxes: $boxes');

      // Initial sync from cloud if logged in (replaces local data)
      if (isLoggedIn) {
        await _initialSyncFromCloud();
      }
    } catch (e) {
      print('❌ Database initialization failed: $e');
      rethrow;
    }
  }

  // ============================================
  // USER ID
  // ============================================

  String get _userId {
    final userId = _auth.currentUserId;
    return userId ?? _guestUserId;
  }

  bool get isLoggedIn => _auth.isLoggedIn;
  bool get isGuestMode => !isLoggedIn;

  // ============================================
  // PROFILE METHODS
  // ============================================

  /// Save profile (local-first)
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    try {
      final profileData = {
        ...profile,
        'userId': _userId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 1. Save to Hive (instant)
      await _boxes['user_profile']!.put('profile', profileData);
      print('✅ Profile saved locally');

      // 2. Background sync to cloud
      if (isLoggedIn) {
        _syncProfileToCloud(profileData);
      }
    } catch (e) {
      print('❌ Save profile failed: $e');
      rethrow;
    }
  }

  /// Save document with specific ID (Upsert: Insert or Update)
  /// Used for Seeding or when ID is predetermined.
  Future<void> saveDocument(
    String collectionName,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (!_boxes.containsKey(collectionName)) {
        throw Exception('Box $collectionName not initialized');
      }

      final docData = {
        ...data,
        'id': documentId,
        'userId': _userId,
        // Preserve existing timestamps if they exist, otherwise create new ones
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 1. Save to Hive (Upsert - .put() creates or updates)
      await _boxes[collectionName]!.put(documentId, docData);
      print('✅ Saved to $collectionName locally: $documentId');

      // 2. Background sync
      if (isLoggedIn) {
        _syncDocumentToCloud(collectionName, documentId, docData);
      }
    } catch (e) {
      print('❌ Save document failed: $e');
      rethrow;
    }
  }

  /// Get profile (always from Hive)
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final localProfile = _boxes['user_profile']!.get('profile');
      return localProfile != null
          ? Map<String, dynamic>.from(localProfile)
          : null;
    } catch (e) {
      print('❌ Get profile failed: $e');
      rethrow;
    }
  }

  /// Update profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final currentProfile = await getProfile() ?? {};

      final updatedProfile = {
        ...currentProfile,
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await saveProfile(updatedProfile);
    } catch (e) {
      print('❌ Update profile failed: $e');
      rethrow;
    }
  }

  Future<bool> hasProfile() async {
    return _boxes['user_profile']!.containsKey('profile');
  }

  // ============================================
  // COLLECTION METHODS (Local-First)
  // ============================================

  /// Add document (instant local write + background sync)
  Future<String> addToCollection(
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    try {
      if (!_boxes.containsKey(collectionName)) {
        throw Exception(
          'Box $collectionName not initialized. Add to initialize(boxes: [...])',
        );
      }

      final docId = DateTime.now().millisecondsSinceEpoch.toString();

      final docData = {
        ...data,
        'id': docId,
        'userId': _userId,
        'createdAt': data['timestamp'] ?? DateTime.now().toIso8601String(),
      };

      // 1. Save to Hive (instant)
      await _boxes[collectionName]!.put(docId, docData);
      print('✅ Added to $collectionName locally: $docId');

      // 2. Background sync to cloud
      if (isLoggedIn) {
        _syncDocumentToCloud(collectionName, docId, docData);
      }

      return docId;
    } catch (e) {
      print('❌ Add to $collectionName failed: $e');
      rethrow;
    }
  }

  /// Get single document (always from Hive)
  Future<Map<String, dynamic>?> getFromCollection(
    String collectionName,
    String documentId,
  ) async {
    try {
      final localDoc = _boxes[collectionName]!.get(documentId);
      return localDoc != null ? Map<String, dynamic>.from(localDoc) : null;
    } catch (e) {
      print('❌ Get from $collectionName failed: $e');
      rethrow;
    }
  }

  /// Get all documents (ALWAYS from Hive - zero network calls)
  Future<List<Map<String, dynamic>>> getAllFromCollection(
    String collectionName,
  ) async {
    try {
      if (!_boxes.containsKey(collectionName)) {
        print('⚠️ Box $collectionName not initialized.');
        return [];
      }

      final box = _boxes[collectionName]!;
      final allItems = <Map<String, dynamic>>[];

      // Single pass: filter and collect
      for (var value in box.values) {
        if (value is Map && value['createdAt'] != null) {
          allItems.add(value.cast<String, dynamic>());
        }
      }

      // Sort by createdAt (newest first)
      allItems.sort((a, b) {
        final aTime = a['createdAt'] as String? ?? '';
        final bTime = b['createdAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      return allItems;
    } catch (e, stackTrace) {
      print('❌ Get all from $collectionName failed: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Query collection by date range (always from Hive)
  Future<List<Map<String, dynamic>>> queryCollection(
    String collectionName, {
    DateTime? startDate,
    DateTime? endDate,
    String timestampField = 'createdAt',
  }) async {
    try {
      final box = _boxes[collectionName]!;
      final results = <Map<String, dynamic>>[];

      for (var value in box.values) {
        if (value is! Map || value[timestampField] == null) continue;

        final item = value.cast<String, dynamic>();

        // Date filter
        if (startDate != null || endDate != null) {
          final timestamp = DateTime.parse(item[timestampField]);
          if (startDate != null && timestamp.isBefore(startDate)) continue;
          if (endDate != null && timestamp.isAfter(endDate)) continue;
        }

        results.add(item);
      }

      // Sort
      results.sort(
        (a, b) => b[timestampField].toString().compareTo(
          a[timestampField].toString(),
        ),
      );

      return results;
    } catch (e) {
      print('❌ Query $collectionName failed: $e');
      rethrow;
    }
  }

  /// Update document (local-first)
  Future<void> updateInCollection(
    String collectionName,
    String documentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final existing = await getFromCollection(collectionName, documentId);
      if (existing == null) {
        throw Exception('Document not found: $documentId');
      }

      final updated = {
        ...existing,
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 1. Update Hive (instant)
      await _boxes[collectionName]!.put(documentId, updated);
      print('✅ Updated $collectionName/$documentId locally');

      // 2. Background sync
      if (isLoggedIn) {
        _syncDocumentToCloud(collectionName, documentId, updated);
      }
    } catch (e) {
      print('❌ Update failed: $e');
      rethrow;
    }
  }

  /// Delete document (local-first)
  Future<void> deleteFromCollection(
    String collectionName,
    String documentId,
  ) async {
    try {
      // 1. Delete from Hive (instant)
      await _boxes[collectionName]!.delete(documentId);
      print('✅ Deleted from $collectionName locally: $documentId');

      // 2. Background sync deletion
      if (isLoggedIn) {
        _deleteDocumentFromCloud(collectionName, documentId);
      }
    } catch (e) {
      print('❌ Delete from $collectionName failed: $e');
      rethrow;
    }
  }

  // ============================================
  // BACKGROUND SYNC (Fire-and-forget)
  // ============================================

  /// Sync profile to cloud (non-blocking)
  void _syncProfileToCloud(Map<String, dynamic> profileData) {
    _firestore!
        .collection('users')
        .doc(_userId)
        .set(profileData, SetOptions(merge: true))
        .then((_) => print('✅ Profile synced to cloud'))
        .catchError((e) => print('⚠️ Profile sync failed: $e'));
  }

  /// Sync single document to cloud (non-blocking)
  void _syncDocumentToCloud(
    String collectionName,
    String docId,
    Map<String, dynamic> docData,
  ) {
    _firestore!
        .collection('users')
        .doc(_userId)
        .collection(collectionName)
        .doc(docId)
        .set(docData)
        .then((_) => print('✅ Synced to cloud: $collectionName/$docId'))
        .catchError(
          (e) => print('⚠️ Sync failed for $collectionName/$docId: $e'),
        );
  }

  /// Delete from cloud (non-blocking)
  void _deleteDocumentFromCloud(String collectionName, String documentId) {
    _firestore!
        .collection('users')
        .doc(_userId)
        .collection(collectionName)
        .doc(documentId)
        .delete()
        .then((_) => print('✅ Deleted from cloud: $collectionName/$documentId'))
        .catchError((e) => print('⚠️ Cloud delete failed: $e'));
  }

  // ============================================
  // INITIAL SYNC (Replace local with cloud data)
  // ============================================

  /// Initial sync: Replace ALL local data with cloud data
  /// Called once on login/initialization
  Future<void> _initialSyncFromCloud() async {
    print('🔄 Starting initial sync from cloud...');

    try {
      // Sync profile
      final profileDoc = await _firestore!
          .collection('users')
          .doc(_userId)
          .get();

      if (profileDoc.exists) {
        await _boxes['user_profile']!.put('profile', profileDoc.data());
        print('✅ Profile synced from cloud');
      }

      // Sync all collections
      for (var entry in _boxes.entries) {
        final boxName = entry.key;
        if (boxName == 'user_profile') continue; // Already synced

        await _replaceCollectionFromCloud(boxName);
        _hasSyncedOnce[boxName] = true;
      }

      print('✅ Initial sync completed');
    } catch (e) {
      print('❌ Initial sync failed: $e');
    }
  }

  /// Replace entire local collection with cloud data
  Future<void> _replaceCollectionFromCloud(String collectionName) async {
    try {
      print('🔄 Syncing $collectionName from cloud...');

      // Fetch all cloud data
      final snapshot = await _firestore!
          .collection('users')
          .doc(_userId)
          .collection(collectionName)
          .get();

      final box = _boxes[collectionName]!;

      // Clear local data
      await box.clear();

      // Write cloud data to local
      for (var doc in snapshot.docs) {
        await box.put(doc.id, doc.data());
      }

      print('✅ $collectionName synced: ${snapshot.docs.length} items');
    } catch (e) {
      print('❌ Sync failed for $collectionName: $e');
    }
  }

  // ============================================
  // MIGRATION (Guest → Authenticated)
  // ============================================

  /// Migrate guest data to authenticated user
  Future<void> migrateGuestData() async {
    if (isGuestMode) {
      print('⚠️ Still in guest mode, cannot migrate');
      return;
    }

    try {
      int totalMigrated = 0;

      for (var entry in _boxes.entries) {
        final boxName = entry.key;
        final box = entry.value;

        // Get guest items
        final guestItems = <Map<String, dynamic>>[];
        for (var value in box.values) {
          if (value is Map && value['userId'] == _guestUserId) {
            guestItems.add(Map<String, dynamic>.from(value));
          }
        }

        if (guestItems.isEmpty) continue;

        print('🔄 Migrating $boxName: ${guestItems.length} items...');

        // Batch upload to cloud (500 max per batch)
        const batchSize = 500;
        for (var i = 0; i < guestItems.length; i += batchSize) {
          final batch = _firestore!.batch();
          final chunk = guestItems.skip(i).take(batchSize);

          for (var item in chunk) {
            item['userId'] = _userId;
            item['migratedAt'] = DateTime.now().toIso8601String();

            final docRef = _firestore!
                .collection('users')
                .doc(_userId)
                .collection(boxName)
                .doc(item['id']);
            batch.set(docRef, item);

            // Update local
            await box.put(item['id'], item);
          }

          await batch.commit();
          totalMigrated += chunk.length;
        }

        print('✅ Migrated $boxName: ${guestItems.length} items');
      }

      print('✅ Total migrated: $totalMigrated items');

      // After migration, do a full sync to get any other cloud data
      await _initialSyncFromCloud();
    } catch (e) {
      print('❌ Migration failed: $e');
    }
  }

  // ============================================
  // MANUAL SYNC (User-triggered refresh)
  // ============================================

  /// Manual sync: Replace local data with cloud data
  Future<void> syncFromCloud(String collectionName) async {
    if (isGuestMode) {
      print('⚠️ Guest mode: Cannot sync from cloud');
      return;
    }

    await _replaceCollectionFromCloud(collectionName);
  }

  /// Sync all collections from cloud
  Future<void> syncAllFromCloud() async {
    if (isGuestMode) {
      print('⚠️ Guest mode: Cannot sync from cloud');
      return;
    }

    await _initialSyncFromCloud();
  }

  /// Force upload all local data to cloud (useful after offline period)
  Future<void> uploadAllToCloud(String collectionName) async {
    if (isGuestMode) {
      print('⚠️ Guest mode: Cannot upload to cloud');
      return;
    }

    try {
      final box = _boxes[collectionName]!;
      final allItems = box.values
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      if (allItems.isEmpty) {
        print('✅ $collectionName: Nothing to upload');
        return;
      }

      // Batch upload
      const batchSize = 500;
      int uploaded = 0;

      for (var i = 0; i < allItems.length; i += batchSize) {
        final batch = _firestore!.batch();
        final chunk = allItems.skip(i).take(batchSize);

        for (var item in chunk) {
          final docRef = _firestore!
              .collection('users')
              .doc(_userId)
              .collection(collectionName)
              .doc(item['id']);
          batch.set(docRef, item);
        }

        await batch.commit();
        uploaded += chunk.length;
      }

      print('✅ Uploaded $collectionName: $uploaded items');
    } catch (e) {
      print('❌ Upload failed: $e');
    }
  }

  // ============================================
  // UTILITIES
  // ============================================

  bool exists(String collectionName, String documentId) {
    return _boxes[collectionName]!.containsKey(documentId);
  }

  int count(String collectionName) {
    return _boxes[collectionName]!.length;
  }

  Future<void> clearCollection(String collectionName) async {
    await _boxes[collectionName]!.clear();
    print('✅ $collectionName cleared');
  }

  Future<void> clearAllLocalData() async {
    for (var box in _boxes.values) {
      await box.clear();
    }
    print('✅ All local data cleared');
  }

  Future<void> dispose() async {
    for (var box in _boxes.values) {
      await box.close();
    }
    _boxes.clear();
    _hasSyncedOnce.clear();
    _isInitialized = false;
    print('✅ Database disposed');
  }
}
