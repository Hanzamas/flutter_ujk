import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  VoidCallback? _onShakeDetected;
  
  // Shake detection parameters
  static const double _shakeThreshold = 15.0; // Increased threshold
  static const int _shakeCooldownMs = 1500; // Longer cooldown
  
  DateTime? _lastShakeTime;
  bool _isShakeEnabled = true;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    try {
      // Test if sensors are available
      await accelerometerEvents.first.timeout(const Duration(seconds: 2));
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Sensor initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  void startShakeDetection(VoidCallback onShakeDetected) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('Sensors not available on this device');
        return;
      }
    }

    _onShakeDetected = onShakeDetected;
    
    try {
      _accelerometerSubscription = accelerometerEvents.listen(
        (AccelerometerEvent event) {
          _detectShake(event);
        },
        onError: (error) {
          print('Accelerometer error: $error');
        },
      );
    } catch (e) {
      print('Failed to start shake detection: $e');
    }
  }

  void stopShakeDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _onShakeDetected = null;
  }

  void _detectShake(AccelerometerEvent event) {
    if (!_isShakeEnabled) return;
    
    // Calculate acceleration magnitude
    final double acceleration = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // Check if shake threshold is exceeded
    if (acceleration > _shakeThreshold) {
      final now = DateTime.now();
      
      // Check cooldown period
      if (_lastShakeTime == null || 
          now.difference(_lastShakeTime!).inMilliseconds > _shakeCooldownMs) {
        
        _lastShakeTime = now;
        _triggerShake();
      }
    }
  }

  void _triggerShake() {
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Haptic feedback error: $e');
    }
    
    _onShakeDetected?.call();
  }

  void enableShake() => _isShakeEnabled = true;
  void disableShake() => _isShakeEnabled = false;
  bool get isAvailable => _isInitialized;

  void dispose() {
    stopShakeDetection();
  }
}