import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/firebase_service.dart';
import '../../providers/place_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../models/place_model.dart';

class EditItemScreen extends StatefulWidget {
  final String itemId;

  const EditItemScreen({super.key, required this.itemId});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _ratingController = TextEditingController();
  
  String _selectedCategory = '';
  bool _isLoading = false;
  PlaceModel? _currentPlace;

  @override
  void initState() {
    super.initState();
    _loadPlaceData();
  }

  void _loadPlaceData() {
    final placeProvider = context.read<PlaceProvider>();
    _currentPlace = placeProvider.getPlaceById(widget.itemId);
    
    if (_currentPlace != null) {
      _nameController.text = _currentPlace!.name;
      _descriptionController.text = _currentPlace!.description;
      _cityController.text = _currentPlace!.city;
      _addressController.text = _currentPlace!.address ?? '';
      _openingHoursController.text = _currentPlace!.openingHours ?? '';
      _imageUrlController.text = _currentPlace!.imageUrl;
      _latitudeController.text = _currentPlace!.latitude?.toString() ?? '';
      _longitudeController.text = _currentPlace!.longitude?.toString() ?? '';
      _ratingController.text = _currentPlace!.rating?.toString() ?? '';
      _selectedCategory = _currentPlace!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _openingHoursController.dispose();
    _imageUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPlace == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Place')),
        body: const Center(
          child: Text('Place not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Tourist Place',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePlace,
            child: Text(
              'Update',
              style: TextStyle(
                color: _isLoading ? AppColors.textLight : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      // ✅ FIX: Use Stack for proper loading overlay
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Section
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),

                  // Location Section
                  _buildLocationSection(),
                  const SizedBox(height: 24),

                  // Details Section
                  _buildDetailsSection(),
                  const SizedBox(height: 24),

                  // Image Section
                  _buildImageSection(),
                  const SizedBox(height: 40),

                  // Submit Button
                  CustomButton(
                    text: 'Update Place',
                    onPressed: _isLoading ? null : _updatePlace,
                    isLoading: _isLoading,
                  ),
                  
                  // ✅ ADD: Extra spacing for loading overlay
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // ✅ FIX: Proper loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Updating place...',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Consumer<PlaceProvider>(
      builder: (context, placeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Place Name',
              hint: 'Enter the name of the tourist place',
              controller: _nameController,
              prefixIcon: Icons.place_outlined,
              enabled: !_isLoading, // ✅ ADD: Disable when loading
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter place name';
                }
                if (value.trim().length < 3) {
                  return 'Place name must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: placeProvider.categories
                  .where((category) => category['id'] != 'all')
                  .map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Text(category['name']!),
                );
              }).toList(),
              onChanged: _isLoading ? null : (value) { // ✅ ADD: Disable when loading
                setState(() {
                  _selectedCategory = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              label: 'Description',
              hint: 'Describe this tourist place...',
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              enabled: !_isLoading, // ✅ ADD: Disable when loading
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: 'City',
          hint: 'Enter city name',
          controller: _cityController,
          prefixIcon: Icons.location_city_outlined,
          enabled: !_isLoading, // ✅ ADD: Disable when loading
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter city name';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        CustomTextField(
          label: 'Full Address',
          hint: 'Enter complete address',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
          enabled: !_isLoading, // ✅ ADD: Disable when loading
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Latitude',
                hint: '-6.1754',
                controller: _latitudeController,
                prefixIcon: Icons.my_location,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isLoading, // ✅ ADD: Disable when loading
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final lat = double.tryParse(value);
                    if (lat == null || lat < -90 || lat > 90) {
                      return 'Invalid latitude';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Longitude',
                hint: '106.8272',
                controller: _longitudeController,
                prefixIcon: Icons.location_searching,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isLoading, // ✅ ADD: Disable when loading
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final lng = double.tryParse(value);
                    if (lng == null || lng < -180 || lng > 180) {
                      return 'Invalid longitude';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: 'Opening Hours',
          hint: '08:00 - 17:00 or 24 jam',
          controller: _openingHoursController,
          prefixIcon: Icons.access_time_outlined,
          enabled: !_isLoading, // ✅ ADD: Disable when loading
        ),

        const SizedBox(height: 16),

        CustomTextField(
          label: 'Rating (1-5)',
          hint: '4.5',
          controller: _ratingController,
          prefixIcon: Icons.star_outline,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_isLoading, // ✅ ADD: Disable when loading
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final rating = double.tryParse(value);
              if (rating == null || rating < 1 || rating > 5) {
                return 'Rating must be between 1 and 5';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Place Image',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Update the image of this place.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: 'Image URL',
          hint: 'https://images.unsplash.com/photo-...',
          controller: _imageUrlController,
          prefixIcon: Icons.image_outlined,
          enabled: !_isLoading, // ✅ ADD: Disable when loading
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter image URL';
            }
            
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.hasAbsolutePath) {
              return 'Please enter a valid URL';
            }
            
            if (!value.toLowerCase().contains('http')) {
              return 'URL must start with http:// or https://';
            }
            
            return null;
          },
        ),

        if (_imageUrlController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrlController.text,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.borderLight,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 40, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text(
                          'Invalid image URL',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updatePlace() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse optional numeric fields
      double? latitude;
      double? longitude;
      double? rating;

      if (_latitudeController.text.isNotEmpty) {
        latitude = double.tryParse(_latitudeController.text);
      }
      if (_longitudeController.text.isNotEmpty) {
        longitude = double.tryParse(_longitudeController.text);
      }
      if (_ratingController.text.isNotEmpty) {
        rating = double.tryParse(_ratingController.text);
      }

      final updatedPlace = _currentPlace!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        city: _cityController.text.trim(),
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        openingHours: _openingHoursController.text.trim().isNotEmpty 
            ? _openingHoursController.text.trim() 
            : null,
        rating: rating,
        updatedAt: DateTime.now(),
      );

      // Use FirestoreService to update the place
      final firestoreService = FirestoreService();
      await firestoreService.updateDocument(
        FirebaseService.placesCollectionName,
        widget.itemId,
        updatedPlace.toFirestore(),
      );
      
      // Refresh the places list
      final placeProvider = context.read<PlaceProvider>();
      await placeProvider.refresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating place: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}