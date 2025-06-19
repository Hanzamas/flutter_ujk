import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PlaceModel {
  final String id;
  final String name;
  final String description;
  final String city;
  final String category;
  final String imageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? openingHours;
  final double? rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  PlaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.category,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.openingHours,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Create from Firestore document
  factory PlaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PlaceModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      city: data['city'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      address: data['address'],
      openingHours: data['openingHours'],
      rating: data['rating']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Create from Map
  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      city: map['city'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      openingHours: map['openingHours'],
      rating: map['rating']?.toDouble(),
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is String
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] is String
              ? DateTime.parse(map['updatedAt'])
              : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameLowercase': name.toLowerCase(), // For search functionality
      'description': description,
      'city': city,
      'category': category,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'openingHours': openingHours,
      'rating': rating,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'city': city,
      'category': category,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'openingHours': openingHours,
      'rating': rating,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with new values
  PlaceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? city,
    String? category,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? openingHours,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      city: city ?? this.city,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // ✅ FIX: Move extension methods to class methods
  
  // Get full address or fallback to city
  String get fullAddress {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    return city;
  }

  // Check if place is open (if opening hours provided)
  bool get isOpen {
    if (openingHours == null || openingHours!.isEmpty) {
      return true; // Assume open if no hours specified
    }
    
    // Simple check for "24 jam" or "24 hours"
    final lowerHours = openingHours!.toLowerCase();
    if (lowerHours.contains('24')) return true;
    
    // Check for common closed indicators
    if (lowerHours.contains('tutup') || 
        lowerHours.contains('closed') ||
        lowerHours.contains('libur')) {
      return false;
    }
    
    // For demo purposes, assume places are open during day time
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 6 && hour <= 22; // Open 6 AM to 10 PM
  }

  // Get formatted rating
  String get formattedRating {
    if (rating == null) return 'No rating';
    return '${rating!.toStringAsFixed(1)} ⭐';
  }

  // Get category display name
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'landmark':
        return 'Landmark';
      case 'museum':
        return 'Museum';
      case 'nature':
        return 'Alam';
      case 'beach':
        return 'Pantai';
      case 'mountain':
        return 'Gunung';
      case 'temple':
        return 'Candi/Kuil';
      case 'park':
        return 'Taman';
      case 'shopping':
        return 'Belanja';
      case 'culinary':
        return 'Kuliner';
      case 'cultural':
        return 'Budaya';
      case 'adventure':
        return 'Petualangan';
      case 'religious':
        return 'Religi';
      default:
        return category.isNotEmpty ? 
            '${category[0].toUpperCase()}${category.substring(1)}' : 
            'Other';
    }
  }

  // Get truncated description
  String getTruncatedDescription([int maxLength = 100]) {
    if (description.length <= maxLength) return description;
    return '${description.substring(0, maxLength)}...';
  }

  // Check if place has coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  // Get formatted created date
  String get formattedCreatedDate {
    return DateFormat('dd MMM yyyy').format(createdAt);
  }

  // Get formatted updated date
  String get formattedUpdatedDate {
    return DateFormat('dd MMM yyyy, HH:mm').format(updatedAt);
  }

  // Get distance display (placeholder - would need user location)
  String get distanceDisplay {
    // This would be calculated with user's current location
    // For now, return placeholder
    return 'Distance unknown';
  }

  // Check if recently added (within 7 days)
  bool get isRecentlyAdded {
    final difference = DateTime.now().difference(createdAt);
    return difference.inDays <= 7;
  }

  // Check if highly rated
  bool get isHighlyRated {
    return rating != null && rating! >= 4.0;
  }

  // Get status text
  String get statusText {
    if (!isActive) return 'Inactive';
    if (isOpen) return 'Open';
    return 'Closed';
  }

  // Get status color
  String get statusColor {
    if (!isActive) return 'gray';
    if (isOpen) return 'green';
    return 'red';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlaceModel(id: $id, name: $name, city: $city, category: $category, isActive: $isActive)';
  }
}

// ✅ REMOVE: Extension (moved to class methods)
// extension PlaceModelExtension on PlaceModel { ... }