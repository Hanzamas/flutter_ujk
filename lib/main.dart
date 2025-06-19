import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/place_provider.dart';
import 'providers/favorite_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/services/connectivity_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // ✅ Initialize Firebase with proper mobile offline persistence
    await FirebaseService.initialize();
    print('🔥 Firebase initialized successfully');
    
    // ✅ Initialize connectivity service
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();
    print('🌐 Connectivity service initialized successfully');
    
    // ✅ Optional: Get cache info for debugging
    await FirebaseService.getCacheInfo();
    
    runApp(
      MultiProvider(
        providers: [
          // ✅ Connectivity Service - Provide the same instance
          ChangeNotifierProvider.value(value: connectivityService),
          
          // ✅ Auth Provider
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          
          // ✅ Place Provider with Network Awareness
          ChangeNotifierProxyProvider<ConnectivityService, PlaceProvider>(
            create: (_) => PlaceProvider(),
            update: (context, connectivityService, placeProvider) {
              if (placeProvider != null) {
                placeProvider.setConnectivityService(connectivityService);
                return placeProvider;
              } else {
                final newPlaceProvider = PlaceProvider();
                newPlaceProvider.setConnectivityService(connectivityService);
                return newPlaceProvider;
              }
            },
          ),
          
          // ✅ Favorite Provider with proper dependency injection
          ChangeNotifierProxyProvider2<AuthProvider, PlaceProvider, FavoriteProvider>(
            create: (_) => FavoriteProvider(),
            update: (context, authProvider, placeProvider, favoriteProvider) {
              favoriteProvider ??= FavoriteProvider();
              
              // Auto-initialize favorites when user is authenticated
              if (authProvider.isAuthenticated && authProvider.currentUserId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  favoriteProvider!.initializeFavorites(
                    authProvider.currentUserId!,
                    placeProvider,
                  );
                });
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  favoriteProvider!.clearFavorites();
                });
              }
              
              return favoriteProvider;
            },
          ),
        ],
        child: const TourismApp(),
      ),
    );
    
  } catch (e) {
    print('❌ Error during app initialization: $e');
    
    // ✅ Fallback app for initialization errors
    runApp(
      MaterialApp(
        title: 'Tourism Indonesia',
        home: Scaffold(
          appBar: AppBar(title: const Text('Initialization Error')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize the app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}