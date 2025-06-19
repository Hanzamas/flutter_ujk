import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/place_provider.dart';
import 'providers/favorite_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await FirebaseService.initialize();
    
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: connectivityService),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProxyProvider<ConnectivityService, PlaceProvider>(
            create: (_) => PlaceProvider(),
            update: (context, connectivityService, placeProvider) {
              placeProvider?.setConnectivityService(connectivityService);
              return placeProvider ?? PlaceProvider();
            },
          ),
          ChangeNotifierProxyProvider2<AuthProvider, PlaceProvider, FavoriteProvider>(
            create: (_) => FavoriteProvider(),
            update: (context, authProvider, placeProvider, favoriteProvider) {
              favoriteProvider ??= FavoriteProvider();
              
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
    runApp(
      MaterialApp(
        title: 'Tourism Indonesia',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Initialization Failed'),
                const SizedBox(height: 8),
                Text('Error: $e'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}