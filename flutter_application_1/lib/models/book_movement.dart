/// Énumération pour la direction du mouvement
enum MovementDirection {
  /// Déplacer vers la gauche
  left,

  /// Déplacer vers la droite
  right,

  /// Déplacer vers le haut
  up,

  /// Déplacer vers le bas
  down,
}

/// Modèle représentant un mouvement de livre à effectuer
class BookMovement {
  /// Code-barres/ISBN du livre
  final String bookBarcode;

  /// Titre du livre
  final String bookTitle;

  /// Position actuelle du livre
  final int fromPosition;

  /// Position cible du livre
  final int toPosition;

  /// Direction du mouvement
  final MovementDirection direction;

  /// Distance à parcourir (nombre de positions)
  final int distance;

  /// Priorité du mouvement (0 = plus urgent, 5 = moins urgent)
  final int priority;

  /// Instruction texte pour l'utilisateur
  final String instruction;

  /// Indique si ce mouvement a été effectué
  final bool isCompleted;

  /// Constructeur
  BookMovement({
    required this.bookBarcode,
    required this.bookTitle,
    required this.fromPosition,
    required this.toPosition,
    required this.direction,
    required this.distance,
    required this.priority,
    required this.instruction,
    this.isCompleted = false,
  });

  /// Crée une copie avec des valeurs modifiées
  BookMovement copyWith({
    String? bookBarcode,
    String? bookTitle,
    int? fromPosition,
    int? toPosition,
    MovementDirection? direction,
    int? distance,
    int? priority,
    String? instruction,
    bool? isCompleted,
  }) {
    return BookMovement(
      bookBarcode: bookBarcode ?? this.bookBarcode,
      bookTitle: bookTitle ?? this.bookTitle,
      fromPosition: fromPosition ?? this.fromPosition,
      toPosition: toPosition ?? this.toPosition,
      direction: direction ?? this.direction,
      distance: distance ?? this.distance,
      priority: priority ?? this.priority,
      instruction: instruction ?? this.instruction,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// وصف أولوية الحركة (عرض للمستخدم)
  String get priorityDescription {
    switch (priority) {
      case 0:
        return 'حرج';
      case 1:
        return 'عالية';
      case 2:
        return 'متوسطة';
      case 3:
        return 'عادية';
      case 4:
      case 5:
        return 'منخفضة';
      default:
        return 'عادية';
    }
  }

  /// نص اتجاه الحركة (عرض للمستخدم)
  String get directionText {
    switch (direction) {
      case MovementDirection.left:
        return 'يسار';
      case MovementDirection.right:
        return 'يمين';
      case MovementDirection.up:
        return 'أعلى';
      case MovementDirection.down:
        return 'أسفل';
    }
  }

  /// Obtient un symbole pour la direction
  String get directionSymbol {
    switch (direction) {
      case MovementDirection.left:
        return '←';
      case MovementDirection.right:
        return '→';
      case MovementDirection.up:
        return '↑';
      case MovementDirection.down:
        return '↓';
    }
  }

  /// Convertit le mouvement en JSON
  Map<String, dynamic> toJson() {
    return {
      'bookBarcode': bookBarcode,
      'bookTitle': bookTitle,
      'fromPosition': fromPosition,
      'toPosition': toPosition,
      'direction': direction.toString(),
      'distance': distance,
      'priority': priority,
      'instruction': instruction,
      'isCompleted': isCompleted,
    };
  }

  /// Crée un mouvement à partir d'un JSON
  factory BookMovement.fromJson(Map<String, dynamic> json) {
    return BookMovement(
      bookBarcode: json['bookBarcode'],
      bookTitle: json['bookTitle'],
      fromPosition: json['fromPosition'],
      toPosition: json['toPosition'],
      direction: MovementDirection.values.firstWhere(
        (e) => e.toString() == json['direction'],
      ),
      distance: json['distance'],
      priority: json['priority'],
      instruction: json['instruction'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  @override
  String toString() =>
      'BookMovement(title: $bookTitle, from: $fromPosition to: $toPosition, direction: $directionSymbol)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookMovement &&
          runtimeType == other.runtimeType &&
          bookBarcode == other.bookBarcode &&
          fromPosition == other.fromPosition;

  @override
  int get hashCode => Object.hash(bookBarcode, fromPosition);
}
