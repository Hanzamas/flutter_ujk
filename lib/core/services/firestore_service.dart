import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  
  // ===== GENERIC CRUD =====
  
  Future<DocumentReference> createDocument(
    String collection, 
    Map<String, dynamic> data,
  ) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    
    return await _firestore.collection(collection).add(data);
  }
  
  Future<DocumentSnapshot> getDocument(String collection, String documentId) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }
  
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(collection).doc(documentId).update(data);
  }
  
  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }
  
  // ===== PLACES SPECIFIC =====
  
  // Get all places
  Stream<QuerySnapshot> streamAllPlaces() {
    return _firestore
        .collection(FirebaseService.placesCollectionName)
        .orderBy('name')
        .snapshots();
  }
  
  // Get places by city
  Stream<QuerySnapshot> streamPlacesByCity(String city) {
    return _firestore
        .collection(FirebaseService.placesCollectionName)
        .where('city', isEqualTo: city)
        .orderBy('name')
        .snapshots();
  }
  
  // Get places by category
  Stream<QuerySnapshot> streamPlacesByCategory(String category) {
    return _firestore
        .collection(FirebaseService.placesCollectionName)
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots();
  }
  
  // Get unique cities from places
  Future<List<String>> getUniqueCities() async {
    final snapshot = await _firestore
        .collection(FirebaseService.placesCollectionName)
        .get();
    
    final cities = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['city'] != null) {
        cities.add(data['city'] as String);
      }
    }
    
    final cityList = cities.toList();
    cityList.sort();
    return cityList;
  }
  
  // Search places
  Future<QuerySnapshot> searchPlaces(String searchTerm) async {
    return await _firestore
        .collection(FirebaseService.placesCollectionName)
        .where('nameLowercase', isGreaterThanOrEqualTo: searchTerm.toLowerCase())
        .where('nameLowercase', isLessThan: searchTerm.toLowerCase() + 'z')
        .get();
  }
}