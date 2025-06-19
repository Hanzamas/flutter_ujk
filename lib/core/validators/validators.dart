import '../constants/app_strings.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }
    
    const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(emailPattern);
    
    if (!regex.hasMatch(value)) {
      return AppStrings.emailInvalid;
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    
    if (value != password) {
      return AppStrings.passwordsNotMatch;
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.nameRequired;
    }
    
    if (value.trim().length < 2) {
      return AppStrings.nameTooShort;
    }
    
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    const phonePattern = r'^[+]?[0-9]{10,15}$';
    final regex = RegExp(phonePattern);
    
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }
  
  // Check if password is strong
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }
  
  // Get password strength
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 8) return 'Fair';
    if (isPasswordStrong(password)) return 'Strong';
    return 'Good';
  }

    // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter URL';
    }
    
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasAbsolutePath) {
      return 'Please enter a valid URL';
    }
    
    if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
      return 'URL must start with http:// or https://';
    }
    
    return null;
  }
  
  // Image URL validation (more specific)
  static String? validateImageUrl(String? value) {
    final urlError = validateUrl(value);
    if (urlError != null) return urlError;
    
    final lowercaseUrl = value!.toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasValidExtension = validExtensions.any((ext) => lowercaseUrl.contains(ext));
    
    if (!hasValidExtension && !lowercaseUrl.contains('unsplash.com')) {
      return 'Please enter a valid image URL';
    }
    
    return null;
  }
  
  // Rating validation
  static String? validateRating(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final rating = double.tryParse(value.trim());
    if (rating == null) {
      return 'Please enter a valid number';
    }
    
    if (rating < 1 || rating > 5) {
      return 'Rating must be between 1 and 5';
    }
    
    return null;
  }
  
  // Coordinate validation
  static String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final lat = double.tryParse(value.trim());
    if (lat == null) {
      return 'Please enter a valid number';
    }
    
    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }
    
    return null;
  }
  
  static String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    final lng = double.tryParse(value.trim());
    if (lng == null) {
      return 'Please enter a valid number';
    }
    
    if (lng < -180 || lng > 180) {
      return 'Longitude must be between -180 and 180';
    }
    
    return null;
  }
}