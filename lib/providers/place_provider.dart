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
  bool _isInitialized = false;
  String? _errorMessage;

  // GETTERS
  List<PlaceModel> get places => _getFilteredPlaces();
  List<PlaceModel> get allPlaces => _places;
  List<String> get cities => _cities;
  List<Map<String, String>> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get selectedCity => _selectedCity;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasPlaces => _places.isNotEmpty;
  int get placesCount => _places.length;
  int get filteredPlacesCount => _getFilteredPlaces().length;

  bool get isOnline => _connectivityService?.isOnline ?? true;
  bool get isOffline => _connectivityService?.isOffline ?? false;
  String get networkStatus => _connectivityService?.connectionType ?? 'Unknown';

  PlaceProvider() {
    _loadCategories();
    print('✅ PlaceProvider basic initialization completed');
  }

  void setConnectivityService(ConnectivityService connectivityService) {
    if (_connectivityService != null) return; // ✅ Prevent duplicate injection
    
    _connectivityService = connectivityService;
    print('🌐 ConnectivityService injected into PlaceProvider');
    connectivityService.addListener(_onNetworkChanged);
    
    if (!_isInitialized) {
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      print('🚀 Starting data initialization...');
      
      await loadPlaces();
      await loadCities();
      
      _isInitialized = true;
      print('✅ PlaceProvider initialization completed');
    } catch (e) {
      print('❌ Error in initialization: $e');
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

  Future<void> loadPlaces({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('📊 Loading places... (online: $isOnline)');
      
      final querySnapshot = await _firestoreService.streamAllPlaces().first;
      _places = querySnapshot.docs
          .map((doc) => PlaceModel.fromFirestore(doc))
          .toList();
      
      _places.sort((a, b) => a.name.compareTo(b.name));
      
      if (_places.isNotEmpty) {
        _clearError();
        if (isOffline) {
          print('📦 Successfully loaded ${_places.length} places from cache');
        } else {
          await _connectivityService?.updateLastSyncTime();
          print('✅ Successfully loaded ${_places.length} places from Firestore');
        }
      } else {
        print('📭 No places found in Firestore');
        _setError(isOffline 
            ? 'No offline data available. Please connect to internet.'
            : 'No places found. Try creating sample data.');
      }
      
    } catch (e) {
      print('❌ Error loading places: $e');
      
      if (_places.isEmpty) {
        _setError(e.toString().contains('offline') || e.toString().contains('network')
            ? 'No offline data available. Please connect to internet.'
            : 'Failed to load data. Please try again.');
      } else {
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

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _initializeData();
    }
  }

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
      notifyListeners();
    }
  }

  void setSelectedCity(String city) {
    if (_selectedCity != city) {
      _selectedCity = city;
      notifyListeners();
    }
  }

  void searchPlaces(String query) {
    if (_searchQuery != query.toLowerCase()) {
      _searchQuery = query.toLowerCase();
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

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
      
      notifyListeners();
      return true;
    } catch (e) {
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
      
      notifyListeners();
      return true;
    } catch (e) {
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
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete place: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    print('🔄 Refreshing data...');
    
    try {
      await Future.wait([
        loadPlaces(forceRefresh: forceRefresh),
        loadCities(),
      ]);
    } catch (e) {
      print('❌ Error during refresh: $e');
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
    } catch (e) {
      _setError('Failed to create sample data: $e');
    } finally {
      _setLoading(false);
    }
  }

  PlaceModel? getPlaceById(String placeId) {
    try {
      return _places.firstWhere((place) => place.id == placeId);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivityService?.removeListener(_onNetworkChanged);
    super.dispose();
  }
}