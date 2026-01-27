/// Modèle représentant la localisation d'un livre dans une bibliothèque
class BookLocation {
  /// ISBN du livre
  final String bookIsbn;

  /// Identifiant de la bibliothèque
  final String libraryId;

  /// Identifiant de l'étage
  final String floorId;

  /// Identifiant du rayon
  final String shelfId;

  /// Position du livre sur le rayon (1-indexed)
  final int position;

  /// Position attendue du livre sur le rayon
  final int expectedPosition;

  /// Indique si le livre est à la bonne position
  final bool isCorrectOrder;

  /// Indique si le livre a été remarqué comme mal placé par un utilisateur
  final bool isFlagged;

  /// Raison pour laquelle le livre est mal placé (optionnel)
  final String? reason;

  /// Date de la dernière vérification
  final DateTime? lastCheckedAt;

  /// Nombre de fois que ce livre a été mal placé
  final int misplacementCount;

  /// Constructeur
  BookLocation({
    required this.bookIsbn,
    required this.libraryId,
    required this.floorId,
    required this.shelfId,
    required this.position,
    required this.expectedPosition,
    required this.isCorrectOrder,
    this.isFlagged = false,
    this.reason,
    this.lastCheckedAt,
    this.misplacementCount = 0,
  });

  /// Crée une copie de la localisation avec des valeurs modifiées
  BookLocation copyWith({
    String? bookIsbn,
    String? libraryId,
    String? floorId,
    String? shelfId,
    int? position,
    int? expectedPosition,
    bool? isCorrectOrder,
    bool? isFlagged,
    String? reason,
    DateTime? lastCheckedAt,
    int? misplacementCount,
  }) {
    return BookLocation(
      bookIsbn: bookIsbn ?? this.bookIsbn,
      libraryId: libraryId ?? this.libraryId,
      floorId: floorId ?? this.floorId,
      shelfId: shelfId ?? this.shelfId,
      position: position ?? this.position,
      expectedPosition: expectedPosition ?? this.expectedPosition,
      isCorrectOrder: isCorrectOrder ?? this.isCorrectOrder,
      isFlagged: isFlagged ?? this.isFlagged,
      reason: reason ?? this.reason,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      misplacementCount: misplacementCount ?? this.misplacementCount,
    );
  }

  /// Convertit la localisation en JSON
  Map<String, dynamic> toJson() {
    return {
      'bookIsbn': bookIsbn,
      'libraryId': libraryId,
      'floorId': floorId,
      'shelfId': shelfId,
      'position': position,
      'expectedPosition': expectedPosition,
      'isCorrectOrder': isCorrectOrder,
      'isFlagged': isFlagged,
      'reason': reason,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'misplacementCount': misplacementCount,
    };
  }

  /// Crée une localisation à partir d'un JSON
  factory BookLocation.fromJson(Map<String, dynamic> json) {
    return BookLocation(
      bookIsbn: json['bookIsbn'],
      libraryId: json['libraryId'],
      floorId: json['floorId'],
      shelfId: json['shelfId'],
      position: json['position'],
      expectedPosition: json['expectedPosition'],
      isCorrectOrder: json['isCorrectOrder'],
      isFlagged: json['isFlagged'] ?? false,
      reason: json['reason'],
      lastCheckedAt: json['lastCheckedAt'] != null ? DateTime.parse(json['lastCheckedAt']) : null,
      misplacementCount: json['misplacementCount'] ?? 0,
    );
  }

  /// Convertit la localisation en format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'bookIsbn': bookIsbn,
      'libraryId': libraryId,
      'floorId': floorId,
      'shelfId': shelfId,
      'position': position,
      'expectedPosition': expectedPosition,
      'isCorrectOrder': isCorrectOrder,
      'isFlagged': isFlagged,
      'reason': reason,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'misplacementCount': misplacementCount,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Crée une localisation à partir d'un document Firestore
  factory BookLocation.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookLocation(
      bookIsbn: data['bookIsbn'] ?? '',
      libraryId: data['libraryId'] ?? '',
      floorId: data['floorId'] ?? '',
      shelfId: data['shelfId'] ?? '',
      position: data['position'] ?? 0,
      expectedPosition: data['expectedPosition'] ?? 0,
      isCorrectOrder: data['isCorrectOrder'] ?? true,
      isFlagged: data['isFlagged'] ?? false,
      reason: data['reason'],
      lastCheckedAt: data['lastCheckedAt'] != null
          ? DateTime.parse(data['lastCheckedAt'])
          : null,
      misplacementCount: data['misplacementCount'] ?? 0,
    );
  }

  /// Calcule la distance entre la position actuelle et attendue
  int get positionDeviation => (expectedPosition - position).abs();

  /// Obtient la direction du mouvement requis
  String get movementDirection {
    if (position == expectedPosition) return 'correct';
    return position < expectedPosition ? 'right' : 'left';
  }

  @override
  String toString() =>
      'BookLocation(isbn: $bookIsbn, shelf: $shelfId, position: $position/$expectedPosition)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookLocation &&
          runtimeType == other.runtimeType &&
          bookIsbn == other.bookIsbn &&
          libraryId == other.libraryId &&
          shelfId == other.shelfId;

  @override
  int get hashCode => Object.hash(bookIsbn, libraryId, shelfId);
}
