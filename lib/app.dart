import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart'; // ✅ FIX: Correct import path
import 'core/constants/app_colors.dart';
import 'core/services/connectivity_service.dart';
import 'widgets/offline_banner.dart'; // ✅ Use only the enhanced offline banner

class TourismApp extends StatelessWidget {
  const TourismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        return MaterialApp.router(
          title: 'Tourism Indonesia',
          debugShowCheckedModeBanner: false,
          
          // ✅ Enhanced theme configuration
          theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              centerTitle: false,
            ),
            useMaterial3: true,
            
            // ✅ Enhanced component themes
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            
            cardTheme: CardTheme(
              color: AppColors.surface,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          routerConfig: AppRouter.router,
          
          // ✅ Simplified builder with only essential overlays
          builder: (context, child) {
            return Stack(
              children: [
                // Main app content
                child ?? const SizedBox.shrink(),
                
                // ✅ Only the smart offline banner (auto-hide after 4 seconds)
                const OfflineBanner(),
              ],
            );
          },
        );
      },
    );
  }
}