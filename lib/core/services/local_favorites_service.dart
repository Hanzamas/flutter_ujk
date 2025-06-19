import 'package:shared_preferences/shared_preferences.dart';

class LocalFavoritesService {
  static const String _favoritesKey = 'user_favorites';
  
  // Get favorites from local storage
  static Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }
  
  // Save favorites to local storage
  static Future<void> saveFavoriteIds(List<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteIds);
  }
  
  // Add to favorites
  static Future<void> addToFavorites(String placeId) async {
    final favorites = await getFavoriteIds();
    if (!favorites.contains(placeId)) {
      favorites.add(placeId);
      await saveFavoriteIds(favorites);
    }
  }
  
  // Remove from favorites
  static Future<void> removeFromFavorites(String placeId) async {
    final favorites = await getFavoriteIds();
    favorites.remove(placeId);
    await saveFavoriteIds(favorites);
  }
  
  // Check if is favorite
  static Future<bool> isFavorite(String placeId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(placeId);
  }
  
  // Clear all favorites
  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}