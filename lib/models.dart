import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _toDate(dynamic value) =>
    value is Timestamp ? value.toDate() : DateTime.now();

class Property {
  final String id;
  final String title;
  final String description;
  final String location;
  final String imageUrl;
  final String category;
  final String ownerId;
  final String ownerName;
  final double price;
  final int bedrooms;
  final int sqft;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.category,
    required this.ownerId,
    required this.ownerName,
    required this.price,
    required this.bedrooms,
    required this.sqft,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory Property.fromMap(Map<String, dynamic> map, String id) {
    return Property(
      id: id,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      category: (map['category'] ?? 'Rent House') as String,
      ownerId: (map['ownerId'] ?? '') as String,
      ownerName: (map['ownerName'] ?? '') as String,
      price: ((map['price'] ?? 0) as num).toDouble(),
      bedrooms: ((map['bedrooms'] ?? 0) as num).toInt(),
      sqft: ((map['sqft'] ?? 0) as num).toInt(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'category': category,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'price': price,
      'bedrooms': bedrooms,
      'sqft': sqft,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      text: (map['text'] ?? '') as String,
      senderId: (map['senderId'] ?? '') as String,
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}