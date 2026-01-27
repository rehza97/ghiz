import 'shelf_book.dart';
import 'book_movement.dart';

/// Modèle représentant un guide de correction pour les livres d'un rayon
class BookCorrectionGuide {
  /// Ordre actuel des livres (tel que détecté)
  final List<ShelfBook> currentOrder;

  /// Ordre attendu des livres (selon la base de données)
  final List<ShelfBook> expectedOrder;

  /// Liste des mouvements requis pour corriger l'ordre
  final List<BookMovement> requiredMoves;

  /// Indique si le rayon est déjà dans le bon ordre
  final bool isInCorrectOrder;

  /// Nombre total d'erreurs trouvées
  final int totalErrorsFound;

  /// Nombre de livres mal positionnés
  final int misplacedBooksCount;

  /// Timestamp de la génération du guide
  final DateTime generatedAt;

  /// Identifiant du rayon
  final String? shelfId;

  /// Constructeur
  BookCorrectionGuide({
    required this.currentOrder,
    required this.expectedOrder,
    required this.requiredMoves,
    required this.isInCorrectOrder,
    required this.totalErrorsFound,
    required this.misplacedBooksCount,
    required this.generatedAt,
    this.shelfId,
  });

  /// Crée une copie avec des valeurs modifiées
  BookCorrectionGuide copyWith({
    List<ShelfBook>? currentOrder,
    List<ShelfBook>? expectedOrder,
    List<BookMovement>? requiredMoves,
    bool? isInCorrectOrder,
    int? totalErrorsFound,
    int? misplacedBooksCount,
    DateTime? generatedAt,
    String? shelfId,
  }) {
    return BookCorrectionGuide(
      currentOrder: currentOrder ?? this.currentOrder,
      expectedOrder: expectedOrder ?? this.expectedOrder,
      requiredMoves: requiredMoves ?? this.requiredMoves,
      isInCorrectOrder: isInCorrectOrder ?? this.isInCorrectOrder,
      totalErrorsFound: totalErrorsFound ?? this.totalErrorsFound,
      misplacedBooksCount: misplacedBooksCount ?? this.misplacedBooksCount,
      generatedAt: generatedAt ?? this.generatedAt,
      shelfId: shelfId ?? this.shelfId,
    );
  }

  /// Obtient le pourcentage d'exactitude du rayon
  double get accuracyPercentage {
    if (currentOrder.isEmpty) return 100.0;
    final correctCount = currentOrder.where((book) => book.isCorrect).length;
    return (correctCount / currentOrder.length) * 100;
  }

  /// Obtient la description de l'exactitude
  String get accuracyDescription {
    if (isInCorrectOrder) return 'Parfait ✓';
    if (accuracyPercentage >= 80) return 'Bon (${accuracyPercentage.toStringAsFixed(0)}%)';
    if (accuracyPercentage >= 50) return 'Moyen (${accuracyPercentage.toStringAsFixed(0)}%)';
    return 'Faible (${accuracyPercentage.toStringAsFixed(0)}%)';
  }

  /// Obtient les mouvements triés par priorité
  List<BookMovement> get prioritySortedMoves {
    final sorted = List<BookMovement>.from(requiredMoves);
    sorted.sort((a, b) => a.priority.compareTo(b.priority));
    return sorted;
  }

  /// Obtient le nombre de mouvements à gauche
  int get leftMovesCount =>
      requiredMoves.where((m) => m.direction == MovementDirection.left).length;

  /// Obtient le nombre de mouvements à droite
  int get rightMovesCount =>
      requiredMoves.where((m) => m.direction == MovementDirection.right).length;

  /// Convertit le guide en JSON
  Map<String, dynamic> toJson() {
    return {
      'currentOrder': currentOrder.map((b) => b.toJson()).toList(),
      'expectedOrder': expectedOrder.map((b) => b.toJson()).toList(),
      'requiredMoves': requiredMoves.map((m) => m.toJson()).toList(),
      'isInCorrectOrder': isInCorrectOrder,
      'totalErrorsFound': totalErrorsFound,
      'misplacedBooksCount': misplacedBooksCount,
      'generatedAt': generatedAt.toIso8601String(),
      'shelfId': shelfId,
    };
  }

  /// Crée un guide à partir d'un JSON
  factory BookCorrectionGuide.fromJson(Map<String, dynamic> json) {
    return BookCorrectionGuide(
      currentOrder: (json['currentOrder'] as List)
          .map((b) => ShelfBook.fromJson(b))
          .toList(),
      expectedOrder: (json['expectedOrder'] as List)
          .map((b) => ShelfBook.fromJson(b))
          .toList(),
      requiredMoves: (json['requiredMoves'] as List)
          .map((m) => BookMovement.fromJson(m))
          .toList(),
      isInCorrectOrder: json['isInCorrectOrder'],
      totalErrorsFound: json['totalErrorsFound'],
      misplacedBooksCount: json['misplacedBooksCount'],
      generatedAt: DateTime.parse(json['generatedAt']),
      shelfId: json['shelfId'],
    );
  }

  @override
  String toString() =>
      'BookCorrectionGuide(accuracy: ${accuracyPercentage.toStringAsFixed(0)}%, errors: $totalErrorsFound)';
}
