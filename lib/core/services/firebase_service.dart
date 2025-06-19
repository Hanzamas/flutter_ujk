import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore? _firestore;
  static FirebaseFirestore get firestore => _firestore!;
  
  // ✅ Initialize Firebase with proper mobile offline persistence
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    
    // ✅ Configure Firestore for mobile platform
    _firestore = FirebaseFirestore.instance;
    
    try {
      // ✅ For mobile platforms, use Settings instead of enablePersistence()
      _firestore!.settings = const Settings(
        persistenceEnabled: true,        // Enable offline persistence
        cacheSizeBytes: 104857600,       // 100MB cache
        ignoreUndefinedProperties: true, // Ignore undefined fields
      );
      
      print('🔥 Firestore mobile offline persistence enabled successfully');
      print('💾 Cache size: 100MB');
      print('📱 Platform: Mobile (Android/iOS)');
      
    } catch (e) {
      print('⚠️ Error configuring Firestore settings: $e');
      
      // Fallback with basic settings
      try {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
        );
        print('🔥 Firestore basic persistence enabled');
      } catch (fallbackError) {
        print('❌ Could not enable Firestore persistence: $fallbackError');
      }
    }
  }
  
  // Check if user is authenticated
  static bool get isUserAuthenticated => auth.currentUser != null;
  
  // Get current user
  static User? get currentUser => auth.currentUser;
  
  // Get current user ID
  static String? get currentUserId => auth.currentUser?.uid;
  
  // Collections - ONLY 2 COLLECTIONS NEEDED
  static CollectionReference get usersCollection => 
      firestore.collection('users');
  
  static CollectionReference get placesCollection => 
      firestore.collection('places');
  
  // Collection names as constants
  static const String usersCollectionName = 'users';
  static const String placesCollectionName = 'places';
  
  // Predefined categories (no need for collection)
  static const List<String> categories = [
    'landmark',
    'temple', 
    'beach',
    'mountain',
    'museum',
    'park',
    'shopping',
    'culinary',
  ];
  
  static const Map<String, String> categoryDisplayNames = {
    'landmark': 'Landmark',
    'temple': 'Candi/Kuil', 
    'beach': 'Pantai',
    'mountain': 'Gunung',
    'museum': 'Museum',
    'park': 'Taman',
    'shopping': 'Belanja',
    'culinary': 'Kuliner',
  };
  
  // ✅ Cache configuration methods
  static Future<void> configureCacheSettings({
    int cacheSizeMB = 100,
    bool persistenceEnabled = true,
  }) async {
    try {
      final cacheSizeBytes = cacheSizeMB * 1024 * 1024; // Convert MB to bytes
      
      _firestore!.settings = Settings(
        persistenceEnabled: persistenceEnabled,
        cacheSizeBytes: cacheSizeBytes,
        ignoreUndefinedProperties: true,
      );
      
      print('🔥 Firestore cache configured:');
      print('   - Persistence: $persistenceEnabled');
      print('   - Cache size: ${cacheSizeMB}MB');
      
    } catch (e) {
      print('❌ Error configuring cache: $e');
    }
  }
  
  // ✅ Clear cache (for debugging/testing)
  static Future<void> clearCache() async {
    try {
      await _firestore!.clearPersistence();
      print('🗑️ Firestore cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
  
  // ✅ Check cache size (estimated)
  static Future<void> getCacheInfo() async {
    try {
      // Note: Firestore doesn't provide direct cache size info
      // This is a placeholder for cache information
      print('📊 Firestore Cache Info:');
      print('   - Status: ${_firestore != null ? 'Initialized' : 'Not initialized'}');
      print('   - Persistence: Enabled for mobile platform');
      print('   - Max cache size: 100MB');
    } catch (e) {
      print('❌ Error getting cache info: $e');
    }
  }
  
  // ✅ Enable/Disable network (for testing offline behavior)
  static Future<void> enableNetwork() async {
    try {
      await _firestore!.enableNetwork();
      print('🌐 Firestore network enabled');
    } catch (e) {
      print('❌ Error enabling network: $e');
    }
  }
  
  static Future<void> disableNetwork() async {
    try {
      await _firestore!.disableNetwork();
      print('📴 Firestore network disabled (offline mode)');
    } catch (e) {
      print('❌ Error disabling network: $e');
    }
  }
  
  // ✅ Wait for pending writes (useful before going offline)
  static Future<void> waitForPendingWrites() async {
    try {
      await _firestore!.waitForPendingWrites();
      print('✅ All pending writes completed');
    } catch (e) {
      print('❌ Error waiting for pending writes: $e');
    }
  }
}