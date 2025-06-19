import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/place_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_error_widget.dart';
import '../../widgets/custom_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; 

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isDeleting = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<PlaceProvider>(
        builder: (context, placeProvider, child) {
          final place = placeProvider.getPlaceById(widget.itemId);

          if (place == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Place Details'),
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),
              body: const CustomErrorWidget(
                message: 'Place not found',
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Consumer<FavoriteProvider>(
                    builder: (context, favoriteProvider, child) {
                      final isFavorite = favoriteProvider.isFavorite(place.id);
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.error : Colors.white,
                        ),
                        onPressed: () => _toggleFavorite(place.id),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editPlace(place);
                      } else if (value == 'delete') {
                        _deletePlace(place);
                      } else if (value == 'share') {
                        _sharePlace(place);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Edit Place'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Place'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      place.imageUrl.isNotEmpty
                          ? Image.network(
                              place.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppColors.borderLight,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.borderLight,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 60,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.borderLight,
                              child: const Center(
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 60,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                      
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      
                      // Category Badge
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            place.categoryDisplayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Status Badge (if not active)
                      if (!place.isActive)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    place.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (place.isRecentlyAdded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    place.fullAddress, // ✅ Fixed: Use getter method
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (place.rating != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 20, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    place.formattedRating,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (place.isHighlyRated) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Popular',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: AppColors.border),

                      // Opening Hours
                      if (place.openingHours != null && place.openingHours!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                place.isOpen ? Icons.access_time : Icons.access_time_filled, // ✅ Fixed: Use getter method
                                color: place.isOpen ? AppColors.success : AppColors.error,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.isOpen ? 'Open Now' : 'Closed', // ✅ Fixed: Use getter method
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: place.isOpen ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                  Text(
                                    place.openingHours!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                      ],

                      // Description
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About This Place',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              place.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Location Info
                      if (place.hasCoordinates) ...[
                        const Divider(height: 1, color: AppColors.border),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location Coordinates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.my_location, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Lat: ${place.latitude!.toStringAsFixed(6)}, '
                                      'Lng: ${place.longitude!.toStringAsFixed(6)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Additional Info
                      const Divider(height: 1, color: AppColors.border),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Added: ${place.formattedCreatedDate}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.update, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Updated: ${place.formattedUpdatedDate}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<PlaceProvider>(
      builder: (context, placeProvider, child) {
        final place = placeProvider.getPlaceById(widget.itemId);
        if (place == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (place.hasCoordinates) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Directions',
                      onPressed: () => _openDirections(place),
                      type: ButtonType.outline,
                      icon: Icons.directions,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: CustomButton(
                    text: 'Visit Website',
                    onPressed: () => _visitWebsite(place),
                    icon: Icons.language,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleFavorite(String placeId) {
    final favoriteProvider = context.read<FavoriteProvider>();
    
    // ✅ FIX: Check status BEFORE toggling
    final wasAlreadyFavorite = favoriteProvider.isFavorite(placeId);
    
    favoriteProvider.toggleFavorite(placeId);
    
    // ✅ FIX: Show correct message based on PREVIOUS state
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasAlreadyFavorite ? 'Removed from favorites' : 'Added to favorites',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: wasAlreadyFavorite ? AppColors.textSecondary : AppColors.success,
      ),
    );
  }

  void _editPlace(place) {
    final authProvider = context.read<AuthProvider>();
    
    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to edit places'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // ✅ FIX: Use proper route navigation
    context.pushNamed(
      AppRoutes.editItemName,
      pathParameters: {'itemId': place.id},
    );
  }

  void _deletePlace(place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Are you sure you want to delete "${place.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeletePlace(place);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePlace(place) async {
    if (_isDeleting) return; // ✅ Prevent double deletion
    
    setState(() {
      _isDeleting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final placeProvider = context.read<PlaceProvider>();
      final favoriteProvider = context.read<FavoriteProvider>();
      
      // ✅ Check if user can delete this place
      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to delete places'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting place...'),
              ],
            ),
          ),
        );
      }

      // ✅ FIX: Remove from favorites first (prevent errors)
      if (favoriteProvider.isFavorite(place.id)) {
        await favoriteProvider.removeFromFavorites(place.id);
      }

      // Delete from Firestore
      await placeProvider.deletePlace(place.id);
      
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        // ✅ FIX: Navigate first, THEN show success message
        context.pop(); // Go back to previous screen
        
        // ✅ FIX: Use addPostFrameCallback untuk show message after navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('${place.name} deleted successfully'),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if still open
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to delete: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ✅ FIX: Proper URL launching with fallbacks
  void _openDirections(place) async {
    if (!place.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // ✅ FIX: Multiple URL schemes for better compatibility
    final List<String> mapUrls = [
      // Google Maps app intent (Android)
      'google.navigation:q=${place.latitude},${place.longitude}',
      // Google Maps web with app intent
      'https://maps.google.com/?q=${place.latitude},${place.longitude}',
      // Fallback to directions
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    ];

    bool launched = false;
    
    for (String urlString in mapUrls) {
      try {
        final url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url, 
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          break;
        }
      } catch (e) {
        continue; // Try next URL
      }
    }
    
    if (!launched && mounted) {
      // ✅ Final fallback: Copy coordinates to clipboard
      final coordinates = '${place.latitude},${place.longitude}';
      await _copyToClipboard(coordinates);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Could not open maps app'),
              const SizedBox(height: 4),
              Text(
                'Coordinates copied: $coordinates',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: AppColors.textSecondary,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _openDirections(place),
          ),
        ),
      );
    }
  }

  // ✅ FIX: Better website opening with fallbacks
  void _visitWebsite(place) async {
    // ✅ Multiple search engines and approaches
    final List<String> searchUrls = [
      // Google search optimized for tourism
      'https://www.google.com/search?q="${place.name}"+${place.city}+tourism+Indonesia',
      // TripAdvisor search
      'https://www.tripadvisor.com/Search?q=${Uri.encodeComponent(place.name + ' ' + place.city)}',
      // General Google search
      'https://www.google.com/search?q=${Uri.encodeComponent(place.name + ' ' + place.city)}',
    ];

    bool launched = false;
    
    for (String urlString in searchUrls) {
      try {
        final url = Uri.parse(urlString);
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url, 
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          break;
        }
      } catch (e) {
        continue; // Try next URL
      }
    }
    
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open web browser'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Copy Info',
            textColor: Colors.white,
            onPressed: () => _copyPlaceInfo(place),
          ),
        ),
      );
    }
  }

  // ✅ IMPROVED: Proper share implementation
  void _sharePlace(place) async {
    try {
      // ✅ Create comprehensive share content
      final StringBuffer shareContent = StringBuffer();
      shareContent.writeln('🏞️ ${place.name}');
      shareContent.writeln('📍 ${place.fullAddress}');
      shareContent.writeln();
      shareContent.writeln('${place.description}');
      
      if (place.rating != null) {
        shareContent.writeln();
        shareContent.writeln('⭐ Rating: ${place.formattedRating}');
      }
      
      if (place.openingHours != null) {
        shareContent.writeln('🕒 Hours: ${place.openingHours}');
      }
      
      shareContent.writeln();
      shareContent.writeln('📱 Shared via Tourism Explorer');
      
      if (place.hasCoordinates) {
        shareContent.writeln('🗺️ Location: https://maps.google.com/?q=${place.latitude},${place.longitude}');
      }

      // ✅ Use share_plus for proper sharing
      await Share.share(
        shareContent.toString(),
        subject: '${place.name} - Amazing Place in ${place.city}',
      );
      
    } catch (e) {
      if (mounted) {
        // ✅ Fallback: Show content in modal for manual copy
        _showShareModal(place);
      }
    }
  }
    // ✅ ADD: Share modal fallback
  void _showShareModal(place) {
    final shareText = '''🏞️ ${place.name}
📍 ${place.fullAddress}

${place.description}

${place.rating != null ? '⭐ Rating: ${place.formattedRating}\n' : ''}${place.openingHours != null ? '🕒 Hours: ${place.openingHours}\n' : ''}
📱 Shared via Tourism Explorer${place.hasCoordinates ? '\n🗺️ Location: https://maps.google.com/?q=${place.latitude},${place.longitude}' : ''}''';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
            
            Row(
              children: [
                const Icon(Icons.share, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Share Place',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    shareText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Copy Text',
                    onPressed: () async {
                      await _copyToClipboard(shareText);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share text copied to clipboard'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    type: ButtonType.outline,
                    icon: Icons.copy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Try Share',
                    onPressed: () async {
                      Navigator.pop(context);
                      _sharePlace(place);
                    },
                    icon: Icons.share,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
    // ✅ ADD: Utility methods
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      // Handle clipboard error silently
    }
  }
  
  Future<void> _copyPlaceInfo(place) async {
    final info = '${place.name} - ${place.fullAddress}';
    await _copyToClipboard(info);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Place info copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }

}