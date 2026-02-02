import 'book.dart';

/// Modèle représentant un livre sur un rayon avec ses informations de position
class ShelfBook {
  /// Le livre lui-même
  final Book book;

  /// Position actuelle du livre sur le rayon (1-indexed)
  final int currentPosition;

  /// Position attendue du livre sur le rayon
  final int expectedPosition;

  /// Code-barres/ISBN du livre
  final String barcode;

  /// Indique si ce livre est à la bonne position
  final bool isCorrect;

  /// Déviation de position (distance entre position actuelle et attendue)
  final int deviation;

  /// Direction du mouvement requis
  final String? movementDirection;

  /// Constructeur
  ShelfBook({
    required this.book,
    required this.currentPosition,
    required this.expectedPosition,
    required this.barcode,
    required this.isCorrect,
    required this.deviation,
    this.movementDirection,
  });

  /// Crée une copie du livre avec des valeurs modifiées
  ShelfBook copyWith({
    Book? book,
    int? currentPosition,
    int? expectedPosition,
    String? barcode,
    bool? isCorrect,
    int? deviation,
    String? movementDirection,
  }) {
    return ShelfBook(
      book: book ?? this.book,
      currentPosition: currentPosition ?? this.currentPosition,
      expectedPosition: expectedPosition ?? this.expectedPosition,
      barcode: barcode ?? this.barcode,
      isCorrect: isCorrect ?? this.isCorrect,
      deviation: deviation ?? this.deviation,
      movementDirection: movementDirection ?? this.movementDirection,
    );
  }

  /// Convertit le livre en JSON
  Map<String, dynamic> toJson() {
    return {
      'book': book.toJson(),
      'currentPosition': currentPosition,
      'expectedPosition': expectedPosition,
      'barcode': barcode,
      'isCorrect': isCorrect,
      'deviation': deviation,
      'movementDirection': movementDirection,
    };
  }

  /// Crée un livre à partir d'un JSON
  factory ShelfBook.fromJson(Map<String, dynamic> json) {
    return ShelfBook(
      book: Book.fromJson(json['book']),
      currentPosition: json['currentPosition'],
      expectedPosition: json['expectedPosition'],
      barcode: json['barcode'],
      isCorrect: json['isCorrect'],
      deviation: json['deviation'],
      movementDirection: json['movementDirection'],
    );
  }

  /// Calcule la priorité de correction (0 = plus urgent, 5 = moins urgent)
  int get correctionPriority {
    if (isCorrect) return 5;
    if (deviation >= 5) return 0;
    if (deviation >= 3) return 1;
    if (deviation >= 2) return 2;
    return 3;
  }

  /// Obtient une description de l'état du livre
  String get statusDescription {
    if (isCorrect) return 'في المكان الصحيح';
    return 'يجب نقله إلى الموقع $expectedPosition';
  }

  @override
  String toString() =>
      'ShelfBook(title: ${book.title}, position: $currentPosition/$expectedPosition, correct: $isCorrect)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShelfBook &&
          runtimeType == other.runtimeType &&
          barcode == other.barcode &&
          currentPosition == other.currentPosition;

  @override
  int get hashCode => Object.hash(barcode, currentPosition);
}
