import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/swipeable_page.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/place_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/custom_error_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedCity = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final authProvider = context.read<AuthProvider>();
    final placeProvider = context.read<PlaceProvider>();
    
    if (authProvider.currentUserId != null) {
      context.read<FavoriteProvider>().initializeFavorites(
        authProvider.currentUserId!,
        placeProvider,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ WRAP: With SwipeablePage
    return SwipeablePage(
      currentRoute: AppRoutes.favoritesName,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Row(
            children: [
              const Text(
                'My Favorites',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // ✅ Swipe indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe, size: 12, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      'Swipe to navigate',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Consumer<FavoriteProvider>(
              builder: (context, favoriteProvider, child) {
                if (favoriteProvider.hasFavorites) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
                        onPressed: () {
                          _showFilterBottomSheet(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: AppColors.textPrimary),
                        onPressed: () {
                          _showSearchBottomSheet(context);
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        
        // ✅ Keep all existing body content
        body: Consumer<FavoriteProvider>(
          builder: (context, favoriteProvider, child) {
            if (favoriteProvider.isLoading) {
              return const LoadingWidget(message: 'Loading favorites...');
            }

            if (favoriteProvider.errorMessage != null) {
              return CustomErrorWidget(
                message: favoriteProvider.errorMessage!,
                onRetry: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadFavorites();
                  });
                },
              );
            }

            if (!favoriteProvider.hasFavorites) {
              return EmptyStateWidget(
                icon: Icons.favorite_outline,
                title: 'No Favorites Yet',
                message: 'Places you favorite will appear here.\nStart exploring to find places you love!\n\n💡 Swipe right to go to Home screen',
                buttonText: 'Explore Places',
                onButtonPressed: () {
                  context.goNamed(AppRoutes.homeName);
                },
              );
            }

            // Apply filters and search
            List favoritePlaces = favoriteProvider.favoritePlaces;
            
            // Filter by category
            if (_selectedCategory != 'all') {
              favoritePlaces = favoritePlaces
                  .where((place) => place.category == _selectedCategory)
                  .toList();
            }
            
            // Filter by city
            if (_selectedCity != 'all') {
              favoritePlaces = favoritePlaces
                  .where((place) => place.city == _selectedCity)
                  .toList();
            }
            
            // Apply search
            if (_searchQuery.isNotEmpty) {
              favoritePlaces = favoritePlaces.where((place) {
                final query = _searchQuery.toLowerCase();
                return place.name.toLowerCase().contains(query) ||
                       place.description.toLowerCase().contains(query) ||
                       place.city.toLowerCase().contains(query) ||
                       place.category.toLowerCase().contains(query);
              }).toList();
            }

            if (favoritePlaces.isEmpty && (_searchQuery.isNotEmpty || _selectedCategory != 'all' || _selectedCity != 'all')) {
              return _buildFilteredEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authProvider = context.read<AuthProvider>();
                final placeProvider = context.read<PlaceProvider>();
                
                if (authProvider.currentUserId != null) {
                  await favoriteProvider.refreshWithUser(
                    authProvider.currentUserId!,
                    placeProvider,
                  );
                }
              },
              child: Column(
                children: [
                  // Stats and Filters Header
                  _buildStatsHeader(favoriteProvider, favoritePlaces),

                  // Favorites List
                  Expanded(
                    child: favoritePlaces.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.favorite_outline,
                            title: 'No Favorites Found',
                            message: 'No favorites match your current filters.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: favoritePlaces.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final place = favoritePlaces[index];
                              return _buildSwipeableFavoriteCard(place, favoriteProvider);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

    // ✅ ADD: Enhanced favorite card with swipe-to-remove
  Widget _buildSwipeableFavoriteCard(place, FavoriteProvider favoriteProvider) {
    return Dismissible(
      key: Key('favorite_${place.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  'Remove',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onDismissed: (direction) {
        _removeFavoriteWithUndo(place.id, place.name, favoriteProvider);
      },
      child: _buildFavoriteCard(place, favoriteProvider),
    );
  }

  // ✅ ADD: Remove with undo functionality
  void _removeFavoriteWithUndo(String placeId, String placeName, FavoriteProvider favoriteProvider) {
    favoriteProvider.removeFromFavorites(placeId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "$placeName" from favorites'),
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            favoriteProvider.addToFavorites(placeId);
          },
        ),
      ),
    );
  }

  // ✅ Rest of the methods remain the same...
  Widget _buildStatsHeader(FavoriteProvider favoriteProvider, List filteredPlaces) {
    // ... existing code remains the same
    final hasFilters = _searchQuery.isNotEmpty || _selectedCategory != 'all' || _selectedCity != 'all';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${favoriteProvider.favoritesCount} Favorite Place${favoriteProvider.favoritesCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (hasFilters) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Showing ${filteredPlaces.length} result${filteredPlaces.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
          
          // Active Filters
          if (hasFilters) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_searchQuery.isNotEmpty)
                  _buildFilterChip('Search: $_searchQuery', () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  }),
                if (_selectedCategory != 'all')
                  _buildFilterChip('Category: $_selectedCategory', () {
                    setState(() {
                      _selectedCategory = 'all';
                    });
                  }),
                if (_selectedCity != 'all')
                  _buildFilterChip('City: $_selectedCity', () {
                    setState(() {
                      _selectedCity = 'all';
                    });
                  }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(place, FavoriteProvider favoriteProvider) {
    return GestureDetector(
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
        child: Row(
          children: [
            // Place Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                image: place.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(place.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: place.imageUrl.isEmpty
                  ? const Icon(
                      Icons.location_on_outlined,
                      size: 40,
                      color: AppColors.textLight,
                    )
                  : null,
            ),

            // Place Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
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
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            place.categoryDisplayName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (place.rating != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Remove Favorite Button
            Container(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => _removeFavorite(place.id, favoriteProvider),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return EmptyStateWidget(
      icon: Icons.filter_list_off,
      title: 'No Results Found',
      message: 'No favorites match your current filters.\nTry adjusting your search or filters.',
      buttonText: 'Clear Filters',
      onButtonPressed: _clearFilters,
    );
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'all';
      _selectedCity = 'all';
      _searchController.clear();
    });
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<PlaceProvider>(
        builder: (context, placeProvider, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filter Favorites',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Category Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                        ...placeProvider.categories.map((category) {
                          return DropdownMenuItem(
                            value: category['id'],
                            child: Text(category['name']!),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // City Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'City',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: placeProvider.cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city == 'all' ? 'All Cities' : city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value!;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Search Favorites',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search your favorite places...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            Navigator.pop(context);
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
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _removeFavorite(String placeId, FavoriteProvider favoriteProvider) {
    favoriteProvider.toggleFavorite(placeId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.error,
      ),
    );
  }
}