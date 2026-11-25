DateTime _toDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) return DateTime.parse(value);
  if (value is DateTime) return value;
  return DateTime.now();
}

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

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id']?.toString() ?? '',
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      imageUrl: (map['image_url'] ?? '') as String,
      category: (map['category'] ?? 'Rent House') as String,
      ownerId: (map['owner_id'] ?? '') as String,
      ownerName: (map['owner_name'] ?? '') as String,
      price: ((map['price'] ?? 0) as num).toDouble(),
      bedrooms: ((map['bedrooms'] ?? 0) as num).toInt(),
      sqft: ((map['sqft'] ?? 0) as num).toInt(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: _toDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'image_url': imageUrl,
      'category': category,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'price': price,
      'bedrooms': bedrooms,
      'sqft': sqft,
      'latitude': latitude,
      'longitude': longitude,
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

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      text: (map['text'] ?? '') as String,
      senderId: (map['sender_id'] ?? '') as String,
      createdAt: _toDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap(String chatId) {
    return {
      'chat_id': chatId,
      'text': text,
      'sender_id': senderId,
    };
  }
}