import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.uid;

  AuthProvider() {
    _initializeUser();
  }

  // ✅ ENHANCED: Initialize user with better state management
  void _initializeUser() {
    _authService.authStateChanges.listen((User? user) async {
      print('🔄 Auth state changed: ${user?.email ?? 'null'}');
      
      if (user != null) {
        await _loadUserData(user);
      } else {
        _currentUser = null;
      }
      
      notifyListeners();
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(User user) async {
    try {
      final userDoc = await _authService.getUserDocument(user.uid);
      if (userDoc != null && userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
      } else {
        _currentUser = UserModel.fromFirebaseUser(user);
      }
    } catch (e) {
      _currentUser = UserModel.fromFirebaseUser(user);
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        await _loadUserData(user);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email, password, and display name
  Future<bool> signUp(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email, 
        password, 
        displayName
      );
      if (user != null) {
        await _loadUserData(user);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Update local user data
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          displayName: displayName ?? _currentUser!.displayName,
          photoURL: photoURL ?? _currentUser!.photoURL,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Reauthenticate first
      await _authService.reauthenticateUser(currentPassword);
      
      // Update password
      await _authService.updatePassword(newPassword);
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ FIX: Enhanced sign out with immediate state clear
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    
    try {
      // ✅ FIX: Clear user immediately before Firebase call
      _currentUser = null;
      notifyListeners(); // ✅ Notify immediately
      
      // Then call Firebase sign out
      await _authService.signOut();
      
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      _setError(e.toString());
      
      // Even if error, ensure user is cleared
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Reauthenticate first
      await _authService.reauthenticateUser(password);
      
      // Delete account
      await _authService.deleteAccount();
      
      _currentUser = null;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}