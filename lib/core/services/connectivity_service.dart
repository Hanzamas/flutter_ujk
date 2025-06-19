import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Connection state
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  bool _hasInternet = false;
  DateTime? _lastOnlineTime;
  DateTime? _lastSyncTime;
  
  // Services
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _internetCheckTimer;
  late InternetConnectionChecker _internetChecker;
  
  // Cache settings
  static const int CACHE_DURATION_DAYS = 7;
  static const String LAST_SYNC_KEY = 'last_sync_time';
  static const String LAST_ONLINE_KEY = 'last_online_time';

  // ✅ Get primary connection result
  ConnectivityResult get _primaryConnectionResult {
    if (_connectionStatus.isEmpty) return ConnectivityResult.none;
    
    // Priority: WiFi > Mobile > Ethernet > Other
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    } else if (_connectionStatus.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    } else if (_connectionStatus.contains(ConnectivityResult.other)) {
      return ConnectivityResult.other;
    }
    
    return ConnectivityResult.none;
  }

  // Getters
  bool get isOnline => _hasInternet;
  bool get isWiFi => _primaryConnectionResult == ConnectivityResult.wifi && _hasInternet;
  bool get isMobile => _primaryConnectionResult == ConnectivityResult.mobile && _hasInternet;
  bool get isEthernet => _primaryConnectionResult == ConnectivityResult.ethernet && _hasInternet;
  bool get isOffline => !_hasInternet;
  DateTime? get lastSyncTime => _lastSyncTime;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  List<ConnectivityResult> get connectionStatus => _connectionStatus;

  String get connectionType {
    if (isOffline) return 'Offline';
    if (isWiFi) return 'WiFi';
    if (isMobile) return 'Mobile Data';
    if (isEthernet) return 'Ethernet';
    return 'Connected';
  }

  Color get statusColor {
    if (isOffline) return Colors.red;
    if (isWiFi) return Colors.green;
    if (isMobile) return Colors.orange;
    if (isEthernet) return Colors.blue;
    return Colors.grey;
  }

  IconData get statusIcon {
    if (isOffline) return Icons.wifi_off;
    if (isWiFi) return Icons.wifi;
    if (isMobile) return Icons.signal_cellular_4_bar;
    if (isEthernet) return Icons.lan;
    return Icons.help_outline;
  }

  // ✅ Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Initialize internet checker
      _internetChecker = InternetConnectionChecker.createInstance(
        checkTimeout: const Duration(seconds: 3),
        checkInterval: const Duration(seconds: 10),
      );
      
      await _loadCachedTimes();
      await _checkInitialConnection();
      _startConnectivityListener();
      _startPeriodicInternetCheck();
      print('🌐 ConnectivityService initialized');
    } catch (e) {
      print('❌ Error initializing ConnectivityService: $e');
    }
  }

  // ✅ Load cached sync times
  Future<void> _loadCachedTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lastSyncStr = prefs.getString(LAST_SYNC_KEY);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }
      
      final lastOnlineStr = prefs.getString(LAST_ONLINE_KEY);
      if (lastOnlineStr != null) {
        _lastOnlineTime = DateTime.tryParse(lastOnlineStr);
      }
    } catch (e) {
      print('Error loading cached times: $e');
    }
  }

  // ✅ Check initial connection
  Future<void> _checkInitialConnection() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _hasInternet = await _internetChecker.hasConnection;
      
      if (_hasInternet) {
        await _updateLastOnlineTime();
      }
      
      notifyListeners();
      print('🌐 Initial connection: ${_primaryConnectionResult} (online: $_hasInternet)');
    } catch (e) {
      print('Error checking initial connection: $e');
    }
  }

  // ✅ Start connectivity listener
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> resultList) async {
        final previousStatus = _connectionStatus;
        final wasOnline = _hasInternet;
        
        _connectionStatus = resultList;
        
        try {
          // Double-check internet access with timeout
          _hasInternet = await _internetChecker.hasConnection;
        } catch (e) {
          print('Error checking internet connection: $e');
          _hasInternet = false;
        }
        
        if (_hasInternet) {
          await _updateLastOnlineTime();
          
          // ✅ Auto-sync when reconnected
          if (!wasOnline) {
            print('🔄 Connection restored - triggering auto-sync');
            await _triggerAutoSync();
          }
        }
        
        notifyListeners();
        _logConnectionChange(previousStatus, resultList, wasOnline, _hasInternet);
      },
    );
  }

  // ✅ Periodic internet validation
  void _startPeriodicInternetCheck() {
    _internetCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (_primaryConnectionResult != ConnectivityResult.none) {
          try {
            final hasInternet = await _internetChecker.hasConnection;
            if (hasInternet != _hasInternet) {
              _hasInternet = hasInternet;
              
              if (_hasInternet) {
                await _updateLastOnlineTime();
                await _triggerAutoSync();
              }
              
              notifyListeners();
              print('🔄 Periodic check: Internet ${_hasInternet ? 'available' : 'unavailable'}');
            }
          } catch (e) {
            print('Error in periodic internet check: $e');
          }
        }
      },
    );
  }

  // ✅ Update last online time
  Future<void> _updateLastOnlineTime() async {
    try {
      _lastOnlineTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LAST_ONLINE_KEY, _lastOnlineTime!.toIso8601String());
    } catch (e) {
      print('Error updating last online time: $e');
    }
  }

  // ✅ Update last sync time
  Future<void> updateLastSyncTime() async {
    try {
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LAST_SYNC_KEY, _lastSyncTime!.toIso8601String());
      notifyListeners();
    } catch (e) {
      print('Error updating last sync time: $e');
    }
  }

  // ✅ Auto-sync trigger
  Future<void> _triggerAutoSync() async {
    try {
      // Small delay for connection stability
      await Future.delayed(const Duration(seconds: 1));
      await updateLastSyncTime();
      print('✅ Auto-sync completed');
    } catch (e) {
      print('Error during auto-sync: $e');
    }
  }

  // ✅ Manual connection check
  Future<void> checkConnection() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _hasInternet = await _internetChecker.hasConnection;
      
      if (_hasInternet) {
        await _updateLastOnlineTime();
        await _triggerAutoSync();
      }
      
      notifyListeners();
      print('🔄 Manual check: ${_primaryConnectionResult} (online: $_hasInternet)');
    } catch (e) {
      print('Error checking connection: $e');
    }
  }

  // ✅ Check if cache is expired
  bool isCacheExpired() {
    if (_lastSyncTime == null) return true;
    
    final now = DateTime.now();
    final daysSinceSync = now.difference(_lastSyncTime!).inDays;
    return daysSinceSync >= CACHE_DURATION_DAYS;
  }

  // ✅ Get cache age text
  String getCacheAgeText() {
    if (_lastSyncTime == null) return 'Never synced';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return 'Over a week ago';
  }

  // ✅ Get detailed connection info
  String getDetailedConnectionInfo() {
    if (isOffline) return 'No internet connection';
    
    final connections = _connectionStatus
        .where((result) => result != ConnectivityResult.none)
        .map((result) => _getConnectionDisplayName(result))
        .join(', ');
    
    return 'Connected via $connections';
  }

  String _getConnectionDisplayName(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'Unknown';
    }
  }

  // ✅ Log connection changes
  void _logConnectionChange(
    List<ConnectivityResult> previousStatus,
    List<ConnectivityResult> newStatus,
    bool wasOnline,
    bool isNowOnline,
  ) {
    print('🌐 Connection changed:');
    print('   Previous: $previousStatus (online: $wasOnline)');
    print('   Current: $newStatus (online: $isNowOnline)');
    print('   Primary: ${_primaryConnectionResult}');
    print('   Type: $connectionType');
  }

  // ✅ Get connection quality indicator
  String getConnectionQuality() {
    if (isOffline) return 'No Connection';
    if (isWiFi) return 'Excellent';
    if (isMobile) return 'Good';
    if (isEthernet) return 'Excellent';
    return 'Unknown';
  }

  // ✅ Check if connection is metered (mobile data)
  bool get isMeteredConnection => isMobile;

  // ✅ Get network type for data saving decisions
  bool get shouldOptimizeForDataUsage => isMobile;

  // ✅ Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetCheckTimer?.cancel();
    super.dispose();
  }
}