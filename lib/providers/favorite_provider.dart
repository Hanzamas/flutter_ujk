import 'package:flutter/material.dart';
import '../models/local_favorite.dart';
import '../models/place_model.dart';
import '../providers/place_provider.dart';

class FavoriteProvider extends ChangeNotifier {
  List<String> _favoriteIds = [];
  List<PlaceModel> _favoritePlaces = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<String> get favoriteIds => _favoriteIds;
  List<PlaceModel> get favoritePlaces => _favoritePlaces;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasFavorites => _favoriteIds.isNotEmpty;
  int get favoritesCount => _favoriteIds.length;

  FavoriteProvider() {
    // ✅ FIX: Use WidgetsBinding for initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  // Check if place is favorite
  bool isFavorite(String placeId) {
    return _favoriteIds.contains(placeId);
  }

  // ✅ IMPROVED: Load favorites for specific user (compatible with ProfileScreen)
  Future<void> loadFavorites(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // For now, we use local storage (not user-specific)
      // In the future, this could load from Firestore with userId
      _favoriteIds = await LocalFavorite.getFavoriteIds();
      
      // You could extend this to load from Firestore:
      // _favoriteIds = await FirestoreService.getUserFavorites(userId);
      
    } catch (e) {
      _setError('Failed to load favorites: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ IMPROVED: Load favorites from local storage (internal method)
  Future<void> _loadFavorites() async {
    _setLoading(true);
    _clearError();
    
    try {
      _favoriteIds = await LocalFavorite.getFavoriteIds();
    } catch (e) {
      _setError('Failed to load favorites: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ IMPROVED: Load favorite places details
  Future<void> loadFavoritePlaces(PlaceProvider placeProvider) async {
    // Don't set loading here if already loading
    if (!_isLoading) {
      _setLoading(true);
    }
    _clearError();
    
    try {
      _favoritePlaces = _favoriteIds
          .map((id) => placeProvider.getPlaceById(id))
          .where((place) => place != null)
          .cast<PlaceModel>()
          .toList();
          
      // Sort by name
      _favoritePlaces.sort((a, b) => a.name.compareTo(b.name));
      
    } catch (e) {
      _setError('Failed to load favorite places: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ IMPROVED: Initialize favorites with user ID and place provider
  Future<void> initializeFavorites(String userId, PlaceProvider placeProvider) async {
    await loadFavorites(userId);
    await loadFavoritePlaces(placeProvider);
  }

  // Add place to favorites
  Future<bool> addToFavorites(String placeId) async {
    // ✅ FIX: Don't set loading for quick operations
    try {
      final added = await LocalFavorite.addToFavorites(placeId);
      if (added) {
        _favoriteIds = await LocalFavorite.getFavoriteIds();
        notifyListeners();
        return true;
      }
      return false; // Already in favorites
    } catch (e) {
      _setError('Failed to add to favorites: $e');
      return false;
    }
  }

  // Remove place from favorites
  Future<bool> removeFromFavorites(String placeId) async {
    // ✅ FIX: Don't set loading for quick operations
    try {
      final removed = await LocalFavorite.removeFromFavorites(placeId);
      if (removed) {
        _favoriteIds = await LocalFavorite.getFavoriteIds();
        _favoritePlaces.removeWhere((place) => place.id == placeId);
        notifyListeners();
        return true;
      }
      return false; // Not in favorites
    } catch (e) {
      _setError('Failed to remove from favorites: $e');
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String placeId) async {
    // ✅ FIX: Don't set loading for quick operations
    try {
      final newStatus = await LocalFavorite.toggleFavorite(placeId);
      _favoriteIds = await LocalFavorite.getFavoriteIds();
      notifyListeners();
      return newStatus;
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
      return false;
    }
  }

  // Get favorite place by ID
  PlaceModel? getFavoritePlaceById(String placeId) {
    try {
      return _favoritePlaces.firstWhere((place) => place.id == placeId);
    } catch (e) {
      return null;
    }
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    _setLoading(true);
    _clearError();
    
    try {
      await LocalFavorite.clearFavorites();
      _favoriteIds.clear();
      _favoritePlaces.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear favorites: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh favorites
  Future<void> refresh(PlaceProvider placeProvider) async {
    await _loadFavorites();
    await loadFavoritePlaces(placeProvider);
  }

  // ✅ IMPROVED: Refresh favorites with user ID
  Future<void> refreshWithUser(String userId, PlaceProvider placeProvider) async {
    await loadFavorites(userId);
    await loadFavoritePlaces(placeProvider);
  }

  // ✅ IMPROVED: Helper methods - only notify when needed
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // Don't notify here unless error was cleared
    }
  }

  void clearError() {
    _clearError();
  }

  // Get favorites by category
  List<PlaceModel> getFavoritesByCategory(String category) {
    if (category == 'all') return _favoritePlaces;
    return _favoritePlaces
        .where((place) => place.category == category)
        .toList();
  }

  // Get favorites by city
  List<PlaceModel> getFavoritesByCity(String city) {
    if (city == 'all') return _favoritePlaces;
    return _favoritePlaces
        .where((place) => place.city == city)
        .toList();
  }

  // Search in favorites
  List<PlaceModel> searchFavorites(String query) {
    if (query.isEmpty) return _favoritePlaces;
    
    final lowercaseQuery = query.toLowerCase();
    return _favoritePlaces.where((place) {
      return place.name.toLowerCase().contains(lowercaseQuery) ||
             place.description.toLowerCase().contains(lowercaseQuery) ||
             place.city.toLowerCase().contains(lowercaseQuery) ||
             place.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // ✅ IMPROVED: Get recent favorites (last 5)
  List<PlaceModel> getRecentFavorites({int limit = 5}) {
    if (_favoritePlaces.length <= limit) {
      return _favoritePlaces;
    }
    return _favoritePlaces.take(limit).toList();
  }

  // ✅ IMPROVED: Get favorite statistics
  Map<String, dynamic> getFavoriteStats() {
    final categories = <String, int>{};
    final cities = <String, int>{};
    
    for (final place in _favoritePlaces) {
      categories[place.category] = (categories[place.category] ?? 0) + 1;
      cities[place.city] = (cities[place.city] ?? 0) + 1;
    }
    
    return {
      'totalFavorites': _favoritePlaces.length,
      'categoriesCount': categories.length,
      'citiesCount': cities.length,
      'topCategory': categories.isEmpty ? null : categories.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'topCity': cities.isEmpty ? null : cities.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    };
  }
}