import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class SamplePlacesData {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  static Future<void> clearAndCreateSamplePlaces() async {
    // Clear existing places (optional)
    final existingPlaces = await _firestore
        .collection(FirebaseService.placesCollectionName)
        .get();
    
    // Delete existing documents (optional - comment out if you want to keep)
    for (final doc in existingPlaces.docs) {
      await doc.reference.delete();
    }

    // Create new sample places
    await createSamplePlaces();
  }

  static Future<void> createSamplePlaces() async {
    final samplePlaces = [
      // Jakarta
      {
        'name': 'Monumen Nasional (Monas)',
        'nameLowercase': 'monumen nasional (monas)',
        'description': 'Tugu nasional setinggi 132 meter yang menjadi simbol kemerdekaan Indonesia. Dilengkapi dengan museum sejarah di bagian bawah dan area taman yang luas untuk rekreasi keluarga.',
        'city': 'Jakarta',
        'category': 'landmark',
        'imageUrl': 'https://images.unsplash.com/photo-1555212697-194d092e3b8f?w=500&h=300&fit=crop',
        'latitude': -6.1754,
        'longitude': 106.8272,
        'address': 'Gambir, Jakarta Pusat',
        'openingHours': '08:00 - 16:00',
        'rating': 4.3,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Kota Tua Jakarta',
        'nameLowercase': 'kota tua jakarta',
        'description': 'Kawasan bersejarah dengan arsitektur kolonial Belanda. Terdapat museum, kafe, dan area pejalan kaki yang ramai dikunjungi wisatawan.',
        'city': 'Jakarta',
        'category': 'landmark',
        'imageUrl': 'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=500&h=300&fit=crop',
        'latitude': -6.1352,
        'longitude': 106.8133,
        'address': 'Pinangsia, Tamansari, Jakarta Barat',
        'openingHours': '24 jam',
        'rating': 4.1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Ancol Dreamland',
        'nameLowercase': 'ancol dreamland',
        'description': 'Taman rekreasi terpadu di tepi pantai Jakarta dengan wahana permainan, pantai, dan SeaWorld untuk hiburan keluarga.',
        'city': 'Jakarta',
        'category': 'park',
        'imageUrl': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500&h=300&fit=crop',
        'latitude': -6.1223,
        'longitude': 106.8317,
        'address': 'Ancol, Jakarta Utara',
        'openingHours': '06:00 - 21:00',
        'rating': 4.2,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },

      // Yogyakarta
      {
        'name': 'Candi Borobudur',
        'nameLowercase': 'candi borobudur',
        'description': 'Candi Buddha terbesar di dunia dan situs warisan dunia UNESCO. Masterpiece arsitektur Buddha abad ke-8 dengan relief yang menakjubkan.',
        'city': 'Yogyakarta',
        'category': 'temple',
        'imageUrl': 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=500&h=300&fit=crop',
        'latitude': -7.6079,
        'longitude': 110.2038,
        'address': 'Borobudur, Magelang, Jawa Tengah',
        'openingHours': '06:00 - 17:00',
        'rating': 4.7,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Malioboro Street',
        'nameLowercase': 'malioboro street',
        'description': 'Jalan legendaris Yogyakarta dengan berbagai toko, street food, dan pertunjukan seni jalanan. Pusat wisata belanja dan kuliner.',
        'city': 'Yogyakarta',
        'category': 'shopping',
        'imageUrl': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=500&h=300&fit=crop',
        'latitude': -7.7928,
        'longitude': 110.3695,
        'address': 'Malioboro, Yogyakarta',
        'openingHours': '24 jam',
        'rating': 4.4,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Keraton Yogyakarta',
        'nameLowercase': 'keraton yogyakarta',
        'description': 'Istana resmi Kesultanan Ngayogyakarta Hadiningrat. Kompleks istana dengan arsitektur Jawa klasik dan museum kebudayaan.',
        'city': 'Yogyakarta',
        'category': 'landmark',
        'imageUrl': 'https://images.unsplash.com/photo-1609137144813-7d9921338f24?w=500&h=300&fit=crop',
        'latitude': -7.8053,
        'longitude': 110.3642,
        'address': 'Kraton, Yogyakarta',
        'openingHours': '08:00 - 15:00',
        'rating': 4.5,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },

      // Bali
      {
        'name': 'Tanah Lot',
        'nameLowercase': 'tanah lot',
        'description': 'Pura yang terletak di atas batu karang di laut. Tempat terbaik untuk menikmati sunset di Bali dengan pemandangan yang memukau.',
        'city': 'Bali',
        'category': 'temple',
        'imageUrl': 'https://images.unsplash.com/photo-1537953773345-d172ccf13cf1?w=500&h=300&fit=crop',
        'latitude': -8.6211,
        'longitude': 115.0868,
        'address': 'Beraban, Kediri, Tabanan, Bali',
        'openingHours': '06:00 - 19:00',
        'rating': 4.5,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Kuta Beach',
        'nameLowercase': 'kuta beach',
        'description': 'Pantai terkenal dengan ombak yang cocok untuk surfing dan sunset yang menakjubkan. Ramai dengan aktivitas wisata air.',
        'city': 'Bali',
        'category': 'beach',
        'imageUrl': 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=500&h=300&fit=crop',
        'latitude': -8.7183,
        'longitude': 115.1681,
        'address': 'Kuta, Badung, Bali',
        'openingHours': '24 jam',
        'rating': 4.2,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Ubud Rice Terraces',
        'nameLowercase': 'ubud rice terraces',
        'description': 'Persawahan berundak yang indah dengan pemandangan hijau yang menenangkan. Spot foto favorit dan trekking ringan.',
        'city': 'Bali',
        'category': 'nature',
        'imageUrl': 'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=500&h=300&fit=crop',
        'latitude': -8.4095,
        'longitude': 115.2921,
        'address': 'Ubud, Gianyar, Bali',
        'openingHours': '06:00 - 18:00',
        'rating': 4.6,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },

      // Bandung
      {
        'name': 'Tangkuban Perahu',
        'nameLowercase': 'tangkuban perahu',
        'description': 'Gunung berapi aktif dengan kawah yang dapat dikunjungi. Pemandangan alam yang spektakuler dan udara sejuk pegunungan.',
        'city': 'Bandung',
        'category': 'mountain',
        'imageUrl': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=300&fit=crop',
        'latitude': -6.7593,
        'longitude': 107.6094,
        'address': 'Cikole, Lembang, Bandung Barat',
        'openingHours': '08:00 - 17:00',
        'rating': 4.3,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Braga Street',
        'nameLowercase': 'braga street',
        'description': 'Jalan bersejarah dengan arsitektur Art Deco dan berbagai kafe serta butik. Pusat wisata kuliner dan belanja di Bandung.',
        'city': 'Bandung',
        'category': 'shopping',
        'imageUrl': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=500&h=300&fit=crop',
        'latitude': -6.9175,
        'longitude': 107.6095,
        'address': 'Braga, Sumur Bandung, Bandung',
        'openingHours': '10:00 - 22:00',
        'rating': 4.1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },

      // Surabaya
      {
        'name': 'Tugu Pahlawan',
        'nameLowercase': 'tugu pahlawan',
        'description': 'Monumen peringatan pertempuran 10 November 1945. Simbol kepahlawanan dan perjuangan Surabaya dengan museum di bawahnya.',
        'city': 'Surabaya',
        'category': 'landmark',
        'imageUrl': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&h=300&fit=crop',
        'latitude': -7.2459,
        'longitude': 112.7378,
        'address': 'Pahlawan, Surabaya',
        'openingHours': '08:00 - 16:00',
        'rating': 4.4,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      
      // Medan
      {
        'name': 'Maimun Palace',
        'nameLowercase': 'maimun palace',
        'description': 'Istana Sultan Deli dengan arsitektur Melayu yang indah. Museum budaya dan sejarah Kesultanan Deli.',
        'city': 'Medan',
        'category': 'landmark',
        'imageUrl': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500&h=300&fit=crop',
        'latitude': 3.5952,
        'longitude': 98.6722,
        'address': 'Brigjen Katamso, Medan',
        'openingHours': '08:00 - 17:00',
        'rating': 4.0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    // Add places to Firestore
    for (final place in samplePlaces) {
      await _firestore
          .collection(FirebaseService.placesCollectionName)
          .add(place);
    }
    
    print('✅ Sample places created successfully! Total: ${samplePlaces.length} places');
  }
  
  // Get predefined categories (no need for collection)
  static List<Map<String, String>> getPredefinedCategories() {
    return [
      {'id': 'all', 'name': 'Semua Kategori'},
      {'id': 'landmark', 'name': 'Landmark'},
      {'id': 'temple', 'name': 'Candi/Kuil'},
      {'id': 'beach', 'name': 'Pantai'},
      {'id': 'mountain', 'name': 'Gunung'},
      {'id': 'museum', 'name': 'Museum'},
      {'id': 'park', 'name': 'Taman'},
      {'id': 'shopping', 'name': 'Belanja'},
      {'id': 'culinary', 'name': 'Kuliner'},
      {'id': 'nature', 'name': 'Alam'},
    ];
  }
  
  // Get predefined cities from sample data
  static List<String> getPredefinedCities() {
    return [
      'Jakarta',
      'Yogyakarta', 
      'Bali',
      'Bandung',
      'Surabaya',
      'Medan',
    ];
  }
}