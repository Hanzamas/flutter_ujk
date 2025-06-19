import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sensor_service.dart';
import '../../widgets/swipeable_page.dart';
import '../../providers/place_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_error_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final SensorService _sensorService = SensorService();
  
  // Animation controllers
  late AnimationController _shakeAnimationController;
  late Animation<double> _shakeAnimation;
  
  bool _isRefreshing = false;
  bool _sensorAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupShakeDetection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaceProvider>().refresh();
    });
  }

  void _initializeAnimations() {
    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _shakeAnimationController,
      curve: Curves.elasticIn,
    ));
  }

  void _setupShakeDetection() async {
    final available = await _sensorService.initialize();
    setState(() {
      _sensorAvailable = available;
    });
    
    if (available) {
      _sensorService.startShakeDetection(_onShakeDetected);
    }
  }

  void _onShakeDetected() {
    if (_isRefreshing) return;
    _performShakeRefresh();
  }

  Future<void> _performShakeRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    _shakeAnimationController.forward().then((_) {
      _shakeAnimationController.reverse();
    });

    try {
      await context.read<PlaceProvider>().refresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.refresh, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(_sensorAvailable ? 'Shake detected! Refreshed.' : 'Refreshed!'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sensorService.stopShakeDetection();
    _shakeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ WRAP: With SwipeablePage
    return SwipeablePage(
      currentRoute: AppRoutes.homeName,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                elevation: 0,
                title: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${authProvider.currentUser?.displayNameOrEmail ?? 'Explorer'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Discover amazing places',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_sensorAvailable) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.vibration, size: 12, color: AppColors.success),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Shake enabled',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  if (_isRefreshing)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Refreshing',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                      onPressed: () => context.read<PlaceProvider>().refresh(),
                      tooltip: _sensorAvailable ? 'Refresh or shake device' : 'Refresh',
                    ),
                  
                  // ✅ Gesture navigation hint
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.swipe, color: AppColors.textSecondary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('💡 Swipe left/right to navigate between tabs!'),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      tooltip: 'Swipe navigation help',
                    ),
                  ),
                  
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                    onSelected: (value) async {
                      if (value == 'sample_data') {
                        await _createSampleData();
                      } else if (value == 'sensor_test') {
                        _testSensor();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'sample_data',
                        child: Row(
                          children: [
                            Icon(Icons.data_saver_on),
                            SizedBox(width: 8),
                            Text('Create Sample Data'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'sensor_test',
                        child: Row(
                          children: [
                            Icon(
                              _sensorAvailable ? Icons.sensors : Icons.sensors_off,
                              color: _sensorAvailable ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text('Test Sensor (${_sensorAvailable ? 'Available' : 'Unavailable'})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // ✅ Keep existing body with all functionality
              body: Consumer<PlaceProvider>(
                builder: (context, placeProvider, child) {
                  return Column(
                    children: [
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surface,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search places by name, city, or category...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      placeProvider.clearSearch();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {});
                            placeProvider.searchPlaces(value);
                          },
                        ),
                      ),

                      // Filter Chips Row
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: placeProvider.categories.length,
                                itemBuilder: (context, index) {
                                  final category = placeProvider.categories[index];
                                  final isSelected = placeProvider.selectedCategory == category['id'];
                                  
                                  return _buildFilterChip(
                                    category['name']!,
                                    isSelected,
                                    () => placeProvider.setSelectedCategory(category['id']!),
                                  );
                                },
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: IconButton(
                                onPressed: () => _showCityFilterDialog(placeProvider),
                                icon: Icon(
                                  Icons.location_city,
                                  color: placeProvider.selectedCity != 'all' 
                                      ? AppColors.primary 
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Places List
                      Expanded(
                        child: _buildPlacesList(placeProvider),
                      ),
                    ],
                  );
                },
              ),
              
              floatingActionButton: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return FloatingActionButton(
                    onPressed: () {
                      if (authProvider.isAuthenticated) {
                        context.pushNamed(AppRoutes.addItemName);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login to add places')),
                        );
                        context.pushNamed(AppRoutes.loginName);
                      }
                    },
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.add_location_alt, color: Colors.white),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _testSensor() {
    if (_sensorAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Sensor is working! Try shaking your device.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Sensor not available on this device/emulator.'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesList(PlaceProvider placeProvider) {
    if (placeProvider.isLoading && !_isRefreshing) {
      return const LoadingWidget(message: 'Loading places...');
    }

    if (placeProvider.errorMessage != null) {
      return CustomErrorWidget(
        message: placeProvider.errorMessage!,
        onRetry: () => placeProvider.refresh(),
      );
    }

    if (placeProvider.places.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.location_off_outlined,
        title: 'No Places Found',
        message: placeProvider.searchQuery.isNotEmpty 
            ? 'No places match your search criteria.'
            : 'No tourist places available at the moment.',
        actionText: 'Create Sample Data',
        onAction: () => _createSampleData(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => placeProvider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: placeProvider.places.length,
        itemBuilder: (context, index) {
          final place = placeProvider.places[index];
          return _buildGesturePlaceCard(place, index);
        },
      ),
    );
  }

  // ✅ FIX: Enhanced PlaceCard with proper key and gesture handling
  Widget _buildGesturePlaceCard(place, int index) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFavorite = favoriteProvider.isFavorite(place.id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            // ✅ FIX: Use GestureDetector instead of Dismissible to avoid tree issues
            onLongPress: () => _toggleFavoriteWithFeedback(place, isFavorite),
            onTap: () {
              context.pushNamed(
                AppRoutes.itemDetailName,
                pathParameters: {'itemId': place.id},
              );
            },
            
            child: _buildPlaceCard(place, isFavorite),
          ),
        );
      },
    );
  }

  Widget _buildPlaceCard(place, bool isFavorite) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: place.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(place.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (place.imageUrl.isEmpty)
                  const Center(
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 60,
                      color: AppColors.textLight,
                    ),
                  ),
                
                // Category Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      place.categoryDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // ✅ Enhanced Favorite Indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _toggleFavoriteWithFeedback(place, isFavorite),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFavorite 
                            ? AppColors.primary.withOpacity(0.9)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.white : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // ✅ Long press hint
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Long press ❤️',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Place Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      place.city,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (place.rating != null) ...[
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        place.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                Text(
                  place.getTruncatedDescription(80),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (place.openingHours != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        place.isOpen ? Icons.access_time : Icons.access_time_filled,
                        size: 16,
                        color: place.isOpen ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        place.isOpen ? 'Open • ${place.openingHours}' : 'Closed • ${place.openingHours}',
                        style: TextStyle(
                          fontSize: 12,
                          color: place.isOpen ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Enhanced favorite toggle with proper type handling
  Future<void> _toggleFavoriteWithFeedback(place, bool currentlyFavorite) async {
    HapticFeedback.mediumImpact();
    
    final favoriteProvider = context.read<FavoriteProvider>();
    
    try {
      if (currentlyFavorite) {
        // ✅ FIX: Pass string ID instead of PlaceModel
        await favoriteProvider.removeFromFavorites(place.id);
      } else {
        // ✅ FIX: Pass string ID instead of PlaceModel
        await favoriteProvider.addToFavorites(place.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  currentlyFavorite ? Icons.favorite_border : Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  currentlyFavorite 
                      ? 'Removed from favorites' 
                      : 'Added to favorites',
                ),
              ],
            ),
            backgroundColor: currentlyFavorite ? AppColors.textSecondary : AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                if (currentlyFavorite) {
                  favoriteProvider.addToFavorites(place.id);
                } else {
                  favoriteProvider.removeFromFavorites(place.id);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCityFilterDialog(PlaceProvider placeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by City'),
        // ✅ FIX: Wrap content with proper constraints
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ FIX: Make the list scrollable
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: placeProvider.cities.map((city) {
                        final isSelected = placeProvider.selectedCity == city;
                        return ListTile(
                          title: Text(city == 'all' ? 'All Cities' : city),
                          leading: Radio<String>(
                            value: city,
                            groupValue: placeProvider.selectedCity,
                            onChanged: (value) {
                              placeProvider.setSelectedCity(value!);
                              Navigator.pop(context);
                            },
                          ),
                          selected: isSelected,
                          dense: true, // ✅ FIX: More compact tiles
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSampleData() async {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to create sample data'),
          backgroundColor: AppColors.error,
        ),
      );
      context.pushNamed(AppRoutes.loginName);
      return;
    }
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating sample places...'),
            ],
          ),
        ),
      );
      
      final placeProvider = context.read<PlaceProvider>();
      await placeProvider.createSampleData();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample data created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create sample data: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}