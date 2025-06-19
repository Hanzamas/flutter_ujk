import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  bool _hasChanges = false;
  bool _imageError = false; // ✅ ADD: Track image loading errors

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _photoUrlController.text = user.photoURL ?? '';
    }

    _nameController.addListener(_onFieldChanged);
    _photoUrlController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user != null) {
      final hasNameChanged = _nameController.text != (user.displayName ?? '');
      final hasPhotoChanged = _photoUrlController.text != (user.photoURL ?? '');
      
      setState(() {
        _hasChanges = hasNameChanged || hasPhotoChanged;
        // ✅ Reset image error when URL changes
        if (hasPhotoChanged) {
          _imageError = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return TextButton(
                onPressed: (_hasChanges && !authProvider.isLoading) ? _saveProfile : null,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: (_hasChanges && !authProvider.isLoading) 
                        ? AppColors.primary 
                        : AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const LoadingWidget(message: 'Updating profile...');
          }

          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Text('No user data available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture Preview
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            // ✅ FIX: Properly handle CircleAvatar with conditional properties
                            _buildProfileAvatar(user),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Change your profile photo',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form Fields
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Photo URL (Optional)',
                    hint: 'Enter photo URL',
                    controller: _photoUrlController,
                    prefixIcon: Icons.link_outlined,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final uri = Uri.parse(value);
                          if (!uri.hasAbsolutePath || (!value.startsWith('http://') && !value.startsWith('https://'))) {
                            return 'Please enter a valid URL starting with http:// or https://';
                          }
                          return null;
                        } catch (e) {
                          return 'Please enter a valid URL';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Helper Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can use image URLs from services like Unsplash, Gravatar, or any public image hosting service.',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ ADD: Image error feedback
                  if (_imageError) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Could not load image from the provided URL. Please check the URL and try again.',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Error Message
                  if (authProvider.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Save Button
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: _hasChanges ? _saveProfile : null,
                    isLoading: authProvider.isLoading,
                  ),

                  const SizedBox(height: 20),

                  // Email Info (Read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user.email ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Read Only',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ FIX: Separate method for building avatar with proper conditions
  Widget _buildProfileAvatar(user) {
    // Determine which image URL to use
    String? imageUrl;
    
    // Priority: current input > existing user photo
    if (_photoUrlController.text.isNotEmpty && !_imageError) {
      imageUrl = _photoUrlController.text;
    } else if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      imageUrl = user.photoURL;
    }

    // Get display text for avatar
    String displayText = '';
    if (_nameController.text.isNotEmpty) {
      displayText = _nameController.text[0].toUpperCase();
    } else if (user.displayName != null && user.displayName!.isNotEmpty) {
      displayText = user.displayName![0].toUpperCase();
    } else if (user.email != null && user.email!.isNotEmpty) {
      displayText = user.email![0].toUpperCase();
    } else {
      displayText = 'U';
    }

    // ✅ Build CircleAvatar with proper conditions
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Has image URL - include error handler
      return CircleAvatar(
        radius: 60,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // ✅ Handle image load error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _imageError = true;
              });
            }
          });
        },
        child: null, // No fallback child when there's an image
      );
    } else {
      // No image URL - show text avatar without error handler
      return CircleAvatar(
        radius: 60,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(
          displayText,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check for image errors before saving
    if (_photoUrlController.text.isNotEmpty && _imageError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the image URL error before saving'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.updateProfile(
      displayName: _nameController.text.trim(),
      photoURL: _photoUrlController.text.trim().isEmpty 
          ? null 
          : _photoUrlController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      context.pop();
    }
  }
}