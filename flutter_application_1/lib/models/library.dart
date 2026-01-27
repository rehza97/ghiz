/// Modèle représentant une bibliothèque
class Library {
  /// Identifiant unique de la bibliothèque
  final String id;

  /// Nom de la bibliothèque
  final String name;

  /// Adresse de la bibliothèque
  final String address;

  /// Code postal
  final String postalCode;

  /// Ville
  final String city;

  /// Téléphone
  final String? phone;

  /// Email
  final String? email;

  /// Nombre d'étages
  final int floorCount;

  /// Latitude GPS
  final double latitude;

  /// Longitude GPS
  final double longitude;

  /// URL de l'image du logo
  final String? logoUrl;

  /// Heures d'ouverture
  final String? hours;

  /// Description de la bibliothèque
  final String? description;

  /// Constructeur
  Library({
    required this.id,
    required this.name,
    required this.address,
    required this.postalCode,
    required this.city,
    this.phone,
    this.email,
    required this.floorCount,
    required this.latitude,
    required this.longitude,
    this.logoUrl,
    this.hours,
    this.description,
  });

  /// Crée une copie de la bibliothèque avec des valeurs modifiées
  Library copyWith({
    String? id,
    String? name,
    String? address,
    String? postalCode,
    String? city,
    String? phone,
    String? email,
    int? floorCount,
    double? latitude,
    double? longitude,
    String? logoUrl,
    String? hours,
    String? description,
  }) {
    return Library(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      floorCount: floorCount ?? this.floorCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      logoUrl: logoUrl ?? this.logoUrl,
      hours: hours ?? this.hours,
      description: description ?? this.description,
    );
  }

  /// Convertit la bibliothèque en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'postalCode': postalCode,
      'city': city,
      'phone': phone,
      'email': email,
      'floorCount': floorCount,
      'latitude': latitude,
      'longitude': longitude,
      'logoUrl': logoUrl,
      'hours': hours,
      'description': description,
    };
  }

  /// Crée une bibliothèque à partir d'un JSON
  factory Library.fromJson(Map<String, dynamic> json) {
    return Library(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      postalCode: json['postalCode'],
      city: json['city'],
      phone: json['phone'],
      email: json['email'],
      floorCount: json['floorCount'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      logoUrl: json['logoUrl'],
      hours: json['hours'],
      description: json['description'],
    );
  }

  /// Convertit la bibliothèque en format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'postalCode': postalCode,
      'city': city,
      'wilaya': city, // Use city as wilaya for now
      'phone': phone,
      'email': email,
      'floorCount': floorCount,
      'latitude': latitude,
      'longitude': longitude,
      'logoUrl': logoUrl,
      'hours': hours,
      'description': description,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Crée une bibliothèque à partir d'un document Firestore
  factory Library.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Library(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      postalCode: data['postalCode'] ?? '',
      city: data['city'] ?? '',
      phone: data['phone'],
      email: data['email'],
      floorCount: data['floorCount'] ?? 0,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      logoUrl: data['logoUrl'],
      hours: data['hours'],
      description: data['description'],
    );
  }

  @override
  String toString() => 'Library(id: $id, name: $name, city: $city)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Library && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
