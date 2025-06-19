import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';

class GestureNavigationService {
  static const double _swipeThreshold = 100.0;
  static const double _velocityThreshold = 500.0;

  // Tab navigation order
  static const List<String> _tabOrder = [
    AppRoutes.homeName,
    AppRoutes.favoritesName,
    AppRoutes.profileName,
  ];

  static void handleSwipeNavigation(
    BuildContext context,
    DragEndDetails details,
    String currentRoute,
  ) {
    final velocity = details.velocity.pixelsPerSecond;
    final dx = velocity.dx;
    
    // Check if swipe is fast enough and far enough
    if (dx.abs() < _velocityThreshold) return;
    
    final currentIndex = _tabOrder.indexOf(currentRoute);
    if (currentIndex == -1) return;

    String? targetRoute;
    
    // Swipe right -> Previous tab
    if (dx > 0 && currentIndex > 0) {
      targetRoute = _tabOrder[currentIndex - 1];
    }
    // Swipe left -> Next tab
    else if (dx < 0 && currentIndex < _tabOrder.length - 1) {
      targetRoute = _tabOrder[currentIndex + 1];
    }

    if (targetRoute != null) {
      context.goNamed(targetRoute);
    }
  }

  static String getTabName(String route) {
    switch (route) {
      case AppRoutes.homeName:
        return 'Home';
      case AppRoutes.favoritesName:
        return 'Favorites';
      case AppRoutes.profileName:
        return 'Profile';
      default:
        return 'Unknown';
    }
  }

  static IconData getTabIcon(String route) {
    switch (route) {
      case AppRoutes.homeName:
        return Icons.home;
      case AppRoutes.favoritesName:
        return Icons.favorite;
      case AppRoutes.profileName:
        return Icons.person;
      default:
        return Icons.help;
    }
  }
}