import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/services/connectivity_service.dart';
import 'widgets/network_status_indicator.dart'; // ✅ Minimal indicator
// import 'widgets/network/floating_connection_widget.dart'; // ✅ Full widget
import 'widgets/offline_banner.dart';

class TourismApp extends StatelessWidget {
  const TourismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tourism Indonesia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
      
      builder: (context, child) {
        return Consumer<ConnectivityService>(
          builder: (context, connectivity, _) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                
                // ✅ Choose one approach:
                
                // Option 1: Minimal corner indicator (recommended)
                const NetworkStatusIndicator(),
                
                // Option 2: Full floating widget (comment out if using option 1)
                // const FloatingConnectionWidget(),
                
                // Banner for offline notification
                const OfflineBanner(),
              ],
            );
          },
        );
      },
    );
  }
}