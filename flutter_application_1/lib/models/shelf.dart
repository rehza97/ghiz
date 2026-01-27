/// Modèle représentant un rayon dans une bibliothèque
class Shelf {
  /// Identifiant unique du rayon
  final String id;

  /// Nom du rayon (ex: "A-1-1", "Fiction-1")
  final String name;

  /// Identifiant de l'étage
  final String floorId;

  /// Identifiant de la bibliothèque
  final String libraryId;

  /// Position X du rayon (en mètres ou pixels)
  final double x;

  /// Position Y du rayon (en mètres ou pixels)
  final double y;

  /// Position Z (hauteur/étage)
  final double z;

  /// Largeur du rayon (en mètres ou pixels)
  final double width;

  /// Hauteur du rayon (en mètres ou pixels)
  final double height;

  /// Profondeur du rayon (en mètres ou pixels)
  final double depth;

  /// Catégorie principale des livres (ex: "Fiction", "Science")
  final String? category;

  /// Nombre de positions disponibles sur ce rayon
  final int capacity;

  /// Nombre de livres actuellement sur ce rayon
  final int currentCount;

  /// Description du rayon
  final String? description;

  /// Constructeur
  Shelf({
    required this.id,
    required this.name,
    required this.floorId,
    required this.libraryId,
    required this.x,
    required this.y,
    required this.z,
    required this.width,
    required this.height,
    required this.depth,
    this.category,
    required this.capacity,
    required this.currentCount,
    this.description,
  });

  /// Crée une copie du rayon avec des valeurs modifiées
  Shelf copyWith({
    String? id,
    String? name,
    String? floorId,
    String? libraryId,
    double? x,
    double? y,
    double? z,
    double? width,
    double? height,
    double? depth,
    String? category,
    int? capacity,
    int? currentCount,
    String? description,
  }) {
    return Shelf(
      id: id ?? this.id,
      name: name ?? this.name,
      floorId: floorId ?? this.floorId,
      libraryId: libraryId ?? this.libraryId,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      width: width ?? this.width,
      height: height ?? this.height,
      depth: depth ?? this.depth,
      category: category ?? this.category,
      capacity: capacity ?? this.capacity,
      currentCount: currentCount ?? this.currentCount,
      description: description ?? this.description,
    );
  }

  /// Convertit le rayon en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'floorId': floorId,
      'libraryId': libraryId,
      'x': x,
      'y': y,
      'z': z,
      'width': width,
      'height': height,
      'depth': depth,
      'category': category,
      'capacity': capacity,
      'currentCount': currentCount,
      'description': description,
    };
  }

  /// Crée un rayon à partir d'un JSON
  factory Shelf.fromJson(Map<String, dynamic> json) {
    return Shelf(
      id: json['id'],
      name: json['name'],
      floorId: json['floorId'],
      libraryId: json['libraryId'],
      x: json['x'],
      y: json['y'],
      z: json['z'],
      width: json['width'],
      height: json['height'],
      depth: json['depth'],
      category: json['category'],
      capacity: json['capacity'],
      currentCount: json['currentCount'],
      description: json['description'],
    );
  }

  /// Convertit le rayon en format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'floorId': floorId,
      'libraryId': libraryId,
      'x': x,
      'y': y,
      'z': z,
      'width': width,
      'height': height,
      'depth': depth,
      'category': category,
      'capacity': capacity,
      'currentCount': currentCount,
      'description': description,
      'isActive': true,
      'accuracy': ((capacity - (capacity - currentCount)) / capacity * 100).clamp(0, 100),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Crée un rayon à partir d'un document Firestore
  factory Shelf.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shelf(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      floorId: data['floorId'] ?? '',
      libraryId: data['libraryId'] ?? '',
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      z: (data['z'] ?? 0.0).toDouble(),
      width: (data['width'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      depth: (data['depth'] ?? 0.0).toDouble(),
      category: data['category'],
      capacity: data['capacity'] ?? 0,
      currentCount: data['currentCount'] ?? 0,
      description: data['description'],
    );
  }

  /// Calcule le taux d'occupation du rayon
  double get occupancyRate => currentCount / capacity;

  /// Vérifie si le rayon est plein
  bool get isFull => currentCount >= capacity;

  /// Calcule l'espace disponible
  int get availableSpace => capacity - currentCount;

  @override
  String toString() => 'Shelf(id: $id, name: $name, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shelf && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
