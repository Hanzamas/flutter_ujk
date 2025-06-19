import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/services/connectivity_service.dart';
import 'widgets/offline_banner.dart';

class TourismApp extends StatelessWidget {
  const TourismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        return MaterialApp.router(
          title: 'Tourism Indonesia',
          debugShowCheckedModeBanner: false,
          
          theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          
          routerConfig: AppRouter.router,
          
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const OfflineBanner(),
              ],
            );
          },
        );
      },
    );
  }
}