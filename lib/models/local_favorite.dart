import 'package:shared_preferences/shared_preferences.dart';

class LocalFavorite {
  static const String _favoritesKey = 'user_favorites';
  
  // Get all favorite place IDs
  static Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }
  
  // Save favorite place IDs
  static Future<void> saveFavoriteIds(List<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteIds);
  }
  
  // Add place to favorites
  static Future<bool> addToFavorites(String placeId) async {
    final favorites = await getFavoriteIds();
    if (!favorites.contains(placeId)) {
      favorites.add(placeId);
      await saveFavoriteIds(favorites);
      return true;
    }
    return false; // Already in favorites
  }
  
  // Remove place from favorites
  static Future<bool> removeFromFavorites(String placeId) async {
    final favorites = await getFavoriteIds();
    if (favorites.contains(placeId)) {
      favorites.remove(placeId);
      await saveFavoriteIds(favorites);
      return true;
    }
    return false; // Not in favorites
  }
  
  // Check if place is favorite
  static Future<bool> isFavorite(String placeId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(placeId);
  }
  
  // Toggle favorite status
  static Future<bool> toggleFavorite(String placeId) async {
    final isFav = await isFavorite(placeId);
    if (isFav) {
      await removeFromFavorites(placeId);
      return false;
    } else {
      await addToFavorites(placeId);
      return true;
    }
  }
  
  // Clear all favorites
  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
  
  // Get favorites count
  static Future<int> getFavoritesCount() async {
    final favorites = await getFavoriteIds();
    return favorites.length;
  }
}