/// Modèle représentant un étage d'une bibliothèque
class Floor {
  /// Identifiant unique de l'étage
  final String id;

  /// Nom de l'étage (ex: "Rez-de-chaussée", "1er étage")
  final String name;

  /// Numéro de l'étage (0 = RDC, 1 = 1er étage, etc.)
  final int floorNumber;

  /// Identifiant de la bibliothèque parente
  final String libraryId;

  /// Chemin du fichier du plan de l'étage (image SVG ou PNG)
  final String? mapAssetPath;

  /// Description de l'étage
  final String? description;

  /// Nombre de rayons sur cet étage
  final int shelfCount;

  /// Largeur du plan en pixels
  final double? mapWidth;

  /// Hauteur du plan en pixels
  final double? mapHeight;

  /// Constructeur
  Floor({
    required this.id,
    required this.name,
    required this.floorNumber,
    required this.libraryId,
    this.mapAssetPath,
    this.description,
    required this.shelfCount,
    this.mapWidth,
    this.mapHeight,
  });

  /// Crée une copie de l'étage avec des valeurs modifiées
  Floor copyWith({
    String? id,
    String? name,
    int? floorNumber,
    String? libraryId,
    String? mapAssetPath,
    String? description,
    int? shelfCount,
    double? mapWidth,
    double? mapHeight,
  }) {
    return Floor(
      id: id ?? this.id,
      name: name ?? this.name,
      floorNumber: floorNumber ?? this.floorNumber,
      libraryId: libraryId ?? this.libraryId,
      mapAssetPath: mapAssetPath ?? this.mapAssetPath,
      description: description ?? this.description,
      shelfCount: shelfCount ?? this.shelfCount,
      mapWidth: mapWidth ?? this.mapWidth,
      mapHeight: mapHeight ?? this.mapHeight,
    );
  }

  /// Convertit l'étage en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'floorNumber': floorNumber,
      'libraryId': libraryId,
      'mapAssetPath': mapAssetPath,
      'description': description,
      'shelfCount': shelfCount,
      'mapWidth': mapWidth,
      'mapHeight': mapHeight,
    };
  }

  /// Crée un étage à partir d'un JSON
  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'],
      name: json['name'],
      floorNumber: json['floorNumber'],
      libraryId: json['libraryId'],
      mapAssetPath: json['mapAssetPath'],
      description: json['description'],
      shelfCount: json['shelfCount'],
      mapWidth: json['mapWidth'],
      mapHeight: json['mapHeight'],
    );
  }

  /// Convertit l'étage en format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'floorNumber': floorNumber,
      'libraryId': libraryId,
      'mapAssetPath': mapAssetPath,
      'mapUrl': mapAssetPath, // Firebase Storage URL
      'description': description,
      'shelfCount': shelfCount,
      'mapWidth': mapWidth,
      'mapHeight': mapHeight,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Crée un étage à partir d'un document Firestore
  factory Floor.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Floor(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      floorNumber: data['floorNumber'] ?? 0,
      libraryId: data['libraryId'] ?? '',
      mapAssetPath: data['mapAssetPath'] ?? data['mapUrl'],
      description: data['description'],
      shelfCount: data['shelfCount'] ?? 0,
      mapWidth: data['mapWidth']?.toDouble(),
      mapHeight: data['mapHeight']?.toDouble(),
    );
  }

  @override
  String toString() => 'Floor(id: $id, name: $name, floorNumber: $floorNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Floor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
