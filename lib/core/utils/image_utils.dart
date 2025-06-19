class ImageUtils {
  // Generate random Unsplash image URLs
  static String getRandomImage({
    int width = 400,
    int height = 300,
    String category = 'product',
  }) {
    return 'https://source.unsplash.com/${width}x${height}/?$category&random=${DateTime.now().millisecondsSinceEpoch}';
  }
  
  // Get specific category images from Unsplash
  static String getCategoryImage(String category, {int width = 400, int height = 300}) {
    final categories = {
      'electronics': 'technology,gadget',
      'fashion': 'fashion,clothing',
      'home': 'home,furniture',
      'sports': 'sports,fitness',
      'books': 'books,reading',
    };
    
    final searchTerm = categories[category] ?? 'product';
    return 'https://source.unsplash.com/${width}x${height}/?$searchTerm';
  }
  
  // Generate avatar from name
  static String getAvatarImage(String name) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=2196F3&color=fff&size=200';
  }
  
  // Placeholder image
  static String getPlaceholderImage({int width = 400, int height = 300}) {
    return 'https://via.placeholder.com/${width}x$height/E0E0E0/757575?text=No+Image';
  }
}