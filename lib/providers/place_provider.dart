import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firestore_service.dart';
import '../core/services/firebase_service.dart';
import '../core/services/connectivity_service.dart';
import '../models/place_model.dart';
import '../core/utils/sample_places_data.dart';

class PlaceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  ConnectivityService? _connectivityService;
  
  List<PlaceModel> _places = [];
  List<String> _cities = [];
  List<Map<String, String>> _categories = [];
  String _selectedCategory = 'all';
  String _selectedCity = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ✅ GETTERS
  List<PlaceModel> get places => _getFilteredPlaces();
  List<PlaceModel> get allPlaces => _places;
  List<String> get cities => _cities;
  List<Map<String, String>> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get selectedCity => _selectedCity;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPlaces => _places.isNotEmpty;
  int get placesCount => _places.length;
  int get filteredPlacesCount => _getFilteredPlaces().length;

  // ✅ NETWORK STATUS
  bool get isOnline => _connectivityService?.isOnline ?? false;
  bool get isOffline => _connectivityService?.isOffline ?? true;
  String get networkStatus => _connectivityService?.connectionType ?? 'Unknown';

  PlaceProvider() {
    _initializeData();
  }

  void setConnectivityService(ConnectivityService connectivityService) {
    _connectivityService = connectivityService;
    print('🌐 ConnectivityService injected into PlaceProvider');
    connectivityService.addListener(_onNetworkChanged);
  }

  Future<void> _initializeData() async {
    try {
      _setLoading(true);
      _loadCategories();
      await loadPlaces();
      await loadCities();
      print('✅ PlaceProvider initialized successfully');
    } catch (e) {
      print('❌ Error initializing PlaceProvider: $e');
      _setError('Failed to initialize data: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _onNetworkChanged() {
    if (isOnline && _places.isEmpty) {
      loadPlaces();
    }
  }

  /// ✅ FIX: Improved load places with better state management
  Future<void> loadPlaces({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    _setLoading(true);
    _clearError(); // ✅ Clear error at start
    
    try {
      print('📊 Loading places... (online: $isOnline)');
      
      // ✅ Try to load from Firestore (cache or online)
      final querySnapshot = await _firestoreService.streamAllPlaces().first;
      _places = querySnapshot.docs
          .map((doc) => PlaceModel.fromFirestore(doc))
          .toList();
      
      _places.sort((a, b) => a.name.compareTo(b.name));
      
      // ✅ FIX: Clear error if we successfully got data
      if (_places.isNotEmpty) {
        _clearError(); // ✅ Clear any previous errors
        
        if (isOffline) {
          // Show offline info but not as error
          print('📦 Successfully loaded ${_places.length} places from Firestore cache');
        } else {
          await _connectivityService?.updateLastSyncTime();
          print('✅ Successfully loaded ${_places.length} places from Firestore');
        }
      } else {
        // ✅ Only set error if no data available
        if (isOffline) {
          _setError('No offline data available. Please connect to internet.');
        } else {
          _setError('No places found. Try creating sample data.');
        }
      }
      
    } catch (e) {
      print('❌ Error loading places: $e');
      
      // ✅ Only show error if we don't have any data
      if (_places.isEmpty) {
        if (isOffline) {
          _setError('No offline data available. Please connect to internet.');
        } else {
          _setError('Failed to load data. Check your connection.');
        }
      } else {
        // We have cached data, just show a subtle warning
        print('⚠️ Using cached data due to error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCities() async {
    try {
      final uniqueCities = _places
          .map((place) => place.city)
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      
      _cities = ['all', ...uniqueCities];
      print('📍 Loaded ${uniqueCities.length} unique cities');
      
    } catch (e) {
      print('❌ Error loading cities: $e');
      _cities = ['all', ...SamplePlacesData.getPredefinedCities()];
    }
    
    notifyListeners();
  }

  void _loadCategories() {
    _categories = SamplePlacesData.getPredefinedCategories();
    print('📋 Loaded ${_categories.length} categories');
    notifyListeners();
  }

  // ✅ Rest of filtering methods remain the same...
  List<PlaceModel> _getFilteredPlaces() {
    List<PlaceModel> filteredPlaces = List.from(_places);

    if (_selectedCity != 'all') {
      filteredPlaces = filteredPlaces
          .where((place) => place.city.toLowerCase() == _selectedCity.toLowerCase())
          .toList();
    }

    if (_selectedCategory != 'all') {
      filteredPlaces = filteredPlaces
          .where((place) => place.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredPlaces = filteredPlaces.where((place) {
        final query = _searchQuery.toLowerCase();
        return place.name.toLowerCase().contains(query) ||
               place.description.toLowerCase().contains(query) ||
               place.city.toLowerCase().contains(query) ||
               place.category.toLowerCase().contains(query) ||
               (place.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filteredPlaces;
  }

  void setSelectedCategory(String categoryId) {
    if (_selectedCategory != categoryId) {
      _selectedCategory = categoryId;
      print('🔍 Category filter set to: $categoryId');
      notifyListeners();
    }
  }

  void setSelectedCity(String city) {
    if (_selectedCity != city) {
      _selectedCity = city;
      print('🔍 City filter set to: $city');
      notifyListeners();
    }
  }

  void searchPlaces(String query) {
    if (_searchQuery != query.toLowerCase()) {
      _searchQuery = query.toLowerCase();
      print('🔍 Search query: $_searchQuery');
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      print('🔍 Search cleared');
      notifyListeners();
    }
  }

  void clearAllFilters() {
    bool hasChanges = false;
    
    if (_selectedCategory != 'all') {
      _selectedCategory = 'all';
      hasChanges = true;
    }
    
    if (_selectedCity != 'all') {
      _selectedCity = 'all';
      hasChanges = true;
    }
    
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      hasChanges = true;
    }
    
    if (hasChanges) {
      print('🔍 All filters cleared');
      notifyListeners();
    }
  }

  // ✅ CRUD Operations remain the same...
  Future<bool> createPlace(PlaceModel place) async {
    if (isOffline) {
      _setError('Cannot create places while offline');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      final docRef = await _firestoreService.createDocument(
        FirebaseService.placesCollectionName,
        place.toFirestore(),
      );
      
      final newPlace = place.copyWith(id: docRef.id);
      _places.add(newPlace);
      _places.sort((a, b) => a.name.compareTo(b.name));
      
      await loadCities();
      await _connectivityService?.updateLastSyncTime();
      
      print('✅ Created place: ${newPlace.name}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error creating place: $e');
      _setError('Failed to create place: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePlace(String placeId, PlaceModel updatedPlace) async {
    if (isOffline) {
      _setError('Cannot update places while offline');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await _firestoreService.updateDocument(
        FirebaseService.placesCollectionName,
        placeId,
        updatedPlace.toFirestore(),
      );
      
      final index = _places.indexWhere((place) => place.id == placeId);
      if (index != -1) {
        _places[index] = updatedPlace.copyWith(id: placeId);
        _places.sort((a, b) => a.name.compareTo(b.name));
      }
      
      await loadCities();
      await _connectivityService?.updateLastSyncTime();
      
      print('✅ Updated place: ${updatedPlace.name}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error updating place: $e');
      _setError('Failed to update place: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deletePlace(String placeId) async {
    if (isOffline) {
      _setError('Cannot delete places while offline');
      return false;
    }

    final placeToDelete = getPlaceById(placeId);
    _setLoading(true);
    _clearError();
    
    try {
      await _firestoreService.deleteDocument(
        FirebaseService.placesCollectionName,
        placeId,
      );
      
      _places.removeWhere((place) => place.id == placeId);
      
      await loadCities();
      await _connectivityService?.updateLastSyncTime();
      
      print('✅ Deleted place: ${placeToDelete?.name ?? placeId}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error deleting place: $e');
      _setError('Failed to delete place: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    print('🔄 Refreshing PlaceProvider data...');
    
    try {
      await Future.wait([
        loadPlaces(forceRefresh: forceRefresh),
        loadCities(),
      ]);
      
      print('✅ PlaceProvider refresh completed');
    } catch (e) {
      print('❌ Error during refresh: $e');
      // Don't set error here if we have data
      if (_places.isEmpty) {
        _setError('Failed to refresh data: $e');
      }
    }
  }

  Future<void> createSampleData() async {
    if (isOffline) {
      _setError('Cannot create sample data while offline');
      return;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await SamplePlacesData.createSamplePlaces();
      await refresh();
      print('✅ Sample data created successfully');
    } catch (e) {
      print('❌ Error creating sample data: $e');
      _setError('Failed to create sample data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Query methods
  PlaceModel? getPlaceById(String placeId) {
    try {
      return _places.firstWhere((place) => place.id == placeId);
    } catch (e) {
      return null;
    }
  }

  List<PlaceModel> getPlacesByCity(String city) {
    if (city == 'all') return _places;
    return _places
        .where((place) => place.city.toLowerCase() == city.toLowerCase())
        .toList();
  }

  List<PlaceModel> getPlacesByCategory(String category) {
    if (category == 'all') return _places;
    return _places
        .where((place) => place.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  Stream<List<PlaceModel>> streamPlaces() {
    return _firestoreService.streamAllPlaces().map(
      (querySnapshot) => querySnapshot.docs
          .map((doc) => PlaceModel.fromFirestore(doc))
          .toList(),
    );
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      print('⚠️ PlaceProvider Error: $error');
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _connectivityService?.removeListener(_onNetworkChanged);
    print('🗑️ PlaceProvider disposed');
    super.dispose();
  }
}