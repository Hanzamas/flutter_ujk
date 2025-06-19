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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final SensorService _sensorService = SensorService();
  
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
      _initializeData();
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
    if (mounted) {
      setState(() {
        _sensorAvailable = available;
      });
      
      if (available) {
        _sensorService.startShakeDetection(_onShakeDetected);
      }
    }
  }

  Future<void> _initializeData() async {
    final placeProvider = context.read<PlaceProvider>();
    
    if (!placeProvider.isInitialized) {
      await placeProvider.initialize();
    }
    
    if (placeProvider.places.isEmpty) {
      await placeProvider.refresh();
    }
  }

  void _onShakeDetected() {
    if (_isRefreshing) return;
    _performShakeRefresh();
  }

  Future<void> _performShakeRefresh() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });

    _shakeAnimationController.forward().then((_) {
      if (mounted) {
        _shakeAnimationController.reverse();
      }
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
    return SwipeablePage(
      currentRoute: AppRoutes.homeName,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Scaffold(
                backgroundColor: AppColors.background,
                
                // ✅ FIX: Enhanced AppBar with proper background & colors
                appBar: AppBar(
                  backgroundColor: AppColors.surface, // ✅ Solid white background
                  surfaceTintColor: Colors.transparent, // ✅ Remove Material 3 tint
                  shadowColor: Colors.black.withOpacity(0.1), // ✅ Subtle shadow
                  elevation: 2, // ✅ Add elevation for scroll visibility
                  scrolledUnderElevation: 4, // ✅ Elevation when scrolled
                  automaticallyImplyLeading: false,
                  titleSpacing: 16,
                  
                  // ✅ FIX: System overlay style for status bar
                  systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                  ),
                  
                  title: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hello, ${_getShortName(authProvider.currentUser?.displayNameOrEmail ?? 'Explorer')}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary, // ✅ Ensure dark text
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Discover amazing places',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary, // ✅ Ensure dark text
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          if (_sensorAvailable)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.vibration, size: 12, color: AppColors.success),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Shake',
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
                      );
                    },
                  ),
                  
                  actions: [
                    // ✅ FIX: Refresh button with proper dark color
                    if (_isRefreshing)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          Icons.refresh, 
                          color: AppColors.textPrimary, // ✅ Dark color
                          size: 22,
                        ),
                        onPressed: () => context.read<PlaceProvider>().refresh(),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    
                    // ✅ FIX: Three dots menu with proper dark color
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert, 
                        color: AppColors.textPrimary, // ✅ Dark color for visibility
                        size: 22,
                      ),
                      iconColor: AppColors.textPrimary, // ✅ Additional color specification
                      padding: const EdgeInsets.all(8),
                      color: AppColors.surface, // ✅ White popup background
                      elevation: 8, // ✅ Proper elevation for popup
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // ✅ Rounded corners
                      ),
                      onSelected: (value) async {
                        if (value == 'sample_data') {
                          await _createSampleData();
                        } else if (value == 'sensor_test') {
                          _testSensor();
                        } else if (value == 'help') {
                          _showHelpDialog();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'sample_data',
                          child: Row(
                            children: [
                              Icon(
                                Icons.data_saver_on, 
                                size: 20, 
                                color: AppColors.primary, // ✅ Colored icon
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sample Data',
                                style: TextStyle(
                                  color: AppColors.textPrimary, // ✅ Dark text
                                  fontSize: 14,
                                ),
                              ),
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
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sensor ${_sensorAvailable ? 'OK' : 'Off'}',
                                style: TextStyle(
                                  color: AppColors.textPrimary, // ✅ Dark text
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'help',
                          child: Row(
                            children: [
                              Icon(
                                Icons.help_outline, 
                                size: 20, 
                                color: AppColors.primary, // ✅ Colored icon
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Help',
                                style: TextStyle(
                                  color: AppColors.textPrimary, // ✅ Dark text
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 4), // ✅ Small padding from edge
                  ],
                ),
                body: Consumer<PlaceProvider>(
                  builder: (context, placeProvider, child) {
                    return Column(
                      children: [
                        // Search Bar
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          color: AppColors.surface,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search places...',
                              hintStyle: const TextStyle(fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        placeProvider.clearSearch();
                                      },
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (value) {
                              setState(() {});
                              placeProvider.searchPlaces(value);
                            },
                          ),
                        ),

                        // Filter Chips
                        Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                              
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: IconButton(
                                  onPressed: () => _showCityFilterDialog(placeProvider),
                                  icon: Icon(
                                    Icons.location_city,
                                    color: placeProvider.selectedCity != 'all' 
                                        ? AppColors.primary 
                                        : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                      child: const Icon(Icons.add_location_alt, color: Colors.white, size: 24),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getShortName(String fullName) {
    if (fullName.length <= 15) return fullName;
    
    final parts = fullName.split(' ');
    if (parts.isNotEmpty) {
      return parts.first.length <= 15 ? parts.first : '${parts.first.substring(0, 12)}...';
    }
    
    return '${fullName.substring(0, 12)}...';
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesList(PlaceProvider placeProvider) {
    if (!placeProvider.isInitialized || (placeProvider.isLoading && placeProvider.places.isEmpty)) {
      return const LoadingWidget(message: 'Loading places...');
    }

    if (placeProvider.errorMessage != null && placeProvider.places.isEmpty) {
      return CustomErrorWidget(
        message: placeProvider.errorMessage!,
        onRetry: () async {
          await placeProvider.initialize();
          await placeProvider.refresh();
        },
      );
    }

    if (placeProvider.places.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.location_off_outlined,
        title: 'No Places Found',
        message: placeProvider.searchQuery.isNotEmpty 
            ? 'No places match your search criteria.'
            : 'No tourist places available. Would you like to create some sample data?',
        actionText: 'Create Sample Data',
        onAction: () => _createSampleData(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => placeProvider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: placeProvider.places.length,
        itemBuilder: (context, index) {
          final place = placeProvider.places[index];
          return _buildPlaceCard(place);
        },
      ),
    );
  }

  Widget _buildPlaceCard(place) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFavorite = favoriteProvider.isFavorite(place.id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onLongPress: () => _toggleFavorite(place, isFavorite),
            onTap: () {
              context.pushNamed(
                AppRoutes.itemDetailName,
                pathParameters: {'itemId': place.id},
              );
            },
            child: Container(
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
                  Container(
                    height: 160,
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
                              size: 40,
                              color: AppColors.textLight,
                            ),
                          ),
                        
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              place.categoryDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _toggleFavorite(place, isFavorite),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isFavorite 
                                    ? AppColors.primary.withOpacity(0.9)
                                    : Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.white : AppColors.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.city,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (place.rating != null) ...[
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        Text(
                          place.getTruncatedDescription(60),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(place, bool currentlyFavorite) async {
    HapticFeedback.mediumImpact();
    
    final favoriteProvider = context.read<FavoriteProvider>();
    
    try {
      if (currentlyFavorite) {
        await favoriteProvider.removeFromFavorites(place.id);
      } else {
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
        backgroundColor: AppColors.surface,
        title: const Text('Filter by City'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: double.maxFinite,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: placeProvider.cities.map((city) {
                final isSelected = placeProvider.selectedCity == city;
                return ListTile(
                  title: Text(
                    city == 'all' ? 'All Cities' : city,
                    style: const TextStyle(fontSize: 14),
                  ),
                  leading: Radio<String>(
                    value: city,
                    groupValue: placeProvider.selectedCity,
                    onChanged: (value) {
                      placeProvider.setSelectedCity(value!);
                      Navigator.pop(context);
                    },
                  ),
                  selected: isSelected,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                );
              }).toList(),
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

  void _testSensor() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_sensorAvailable 
            ? '✅ Sensor is working! Try shaking your device.'
            : '❌ Sensor not available on this device/emulator.'),
        backgroundColor: _sensorAvailable ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('💡 How to Use'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('👆', 'Tap places to view details'),
              _buildHelpItem('❤️', 'Long press to add/remove favorites'),
              _buildHelpItem('🔍', 'Use search to find places'),
              _buildHelpItem('🏷️', 'Filter by category or city'),
              _buildHelpItem('↔️', 'Swipe left/right between tabs'),
              if (_sensorAvailable)
                _buildHelpItem('📳', 'Shake device to refresh'),
              _buildHelpItem('➕', 'Use + button to add new places'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
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
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          content: const Column(
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