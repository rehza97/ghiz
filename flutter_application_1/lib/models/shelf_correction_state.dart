import 'shelf_book.dart';
import 'book_movement.dart';

/// Modèle représentant l'état actuel de la correction des livres d'un rayon
class ShelfCorrectionState {
  /// Liste des livres actuellement sur le rayon (tel que détecté)
  final List<ShelfBook> currentBooks;

  /// Mouvements still à effectuer
  final List<BookMovement> remainingMoves;

  /// Nombre de corrections effectuées jusqu'à présent
  final int movesMade;

  /// Pourcentage de progression de la correction
  final double progressPercentage;

  /// Indique si la correction est complète
  final bool correctionComplete;

  /// Timestamp de la dernière mise à jour
  final DateTime lastUpdated;

  /// Mouvements déjà effectués (historique)
  final List<BookMovement> completedMoves;

  /// Constructeur
  ShelfCorrectionState({
    required this.currentBooks,
    required this.remainingMoves,
    required this.movesMade,
    required this.progressPercentage,
    required this.correctionComplete,
    required this.lastUpdated,
    this.completedMoves = const [],
  });

  /// Crée une copie avec des valeurs modifiées
  ShelfCorrectionState copyWith({
    List<ShelfBook>? currentBooks,
    List<BookMovement>? remainingMoves,
    int? movesMade,
    double? progressPercentage,
    bool? correctionComplete,
    DateTime? lastUpdated,
    List<BookMovement>? completedMoves,
  }) {
    return ShelfCorrectionState(
      currentBooks: currentBooks ?? this.currentBooks,
      remainingMoves: remainingMoves ?? this.remainingMoves,
      movesMade: movesMade ?? this.movesMade,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      correctionComplete: correctionComplete ?? this.correctionComplete,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      completedMoves: completedMoves ?? this.completedMoves,
    );
  }

  /// Obtient le prochain mouvement à effectuer
  BookMovement? get nextMove {
    if (remainingMoves.isEmpty) return null;
    // Trier par priorité et retourner le premier
    return remainingMoves.reduce((a, b) => a.priority < b.priority ? a : b);
  }

  /// Obtient le mouvement le plus urgent
  BookMovement? get urgentMove {
    if (remainingMoves.isEmpty) return null;
    return remainingMoves.where((m) => m.priority == 0).firstOrNull;
  }

  /// Nombre de livres mal positionnés
  int get misplacedBooksCount => currentBooks.where((b) => !b.isCorrect).length;

  /// Nombre de livres correctement positionnés
  int get correctBooksCount => currentBooks.where((b) => b.isCorrect).length;

  /// نص الحالة
  String get statusText {
    if (correctionComplete) return 'التصحيح مكتمل ✓';
    if (progressPercentage >= 75) return 'شبه مكتمل';
    if (progressPercentage >= 50) return 'قيد التنفيذ';
    if (progressPercentage >= 25) return 'بدأ';
    return 'لم يبدأ';
  }

  /// وصف تفصيلي للحالة
  String get detailedStatus {
    final moved = '$movesMade حركة منفذة';
    final remaining = '${remainingMoves.length} متبقية';
    return '$moved، $remaining';
  }

  /// Marque un mouvement comme complété
  ShelfCorrectionState markMoveAsCompleted(String bookBarcode) {
    final move = remainingMoves.firstWhere(
      (m) => m.bookBarcode == bookBarcode,
      orElse: () => throw Exception('الحركة غير موجودة'),
    );

    final newRemaining = List<BookMovement>.from(remainingMoves)
      ..removeWhere((m) => m.bookBarcode == bookBarcode);

    final newCompleted = List<BookMovement>.from(completedMoves)
      ..add(move.copyWith(isCompleted: true));

    final newProgress = completedMoves.length / (completedMoves.length + newRemaining.length);

    return ShelfCorrectionState(
      currentBooks: currentBooks,
      remainingMoves: newRemaining,
      movesMade: movesMade + 1,
      progressPercentage: (newProgress * 100).clamp(0, 100),
      correctionComplete: newRemaining.isEmpty,
      lastUpdated: DateTime.now(),
      completedMoves: newCompleted,
    );
  }

  /// Annule le dernier mouvement
  ShelfCorrectionState undoLastMove() {
    if (completedMoves.isEmpty) return this;

    final lastMove = completedMoves.last;
    final newCompleted = List<BookMovement>.from(completedMoves)..removeLast();
    final newRemaining = List<BookMovement>.from(remainingMoves)
      ..add(lastMove.copyWith(isCompleted: false));

    final newProgress =
        newCompleted.length / (newCompleted.length + newRemaining.length);

    return ShelfCorrectionState(
      currentBooks: currentBooks,
      remainingMoves: newRemaining,
      movesMade: (movesMade - 1).clamp(0, movesMade),
      progressPercentage: (newProgress * 100).clamp(0, 100),
      correctionComplete: newRemaining.isEmpty,
      lastUpdated: DateTime.now(),
      completedMoves: newCompleted,
    );
  }

  /// Réinitialise l'état de correction
  ShelfCorrectionState reset() {
    return ShelfCorrectionState(
      currentBooks: currentBooks,
      remainingMoves: [...completedMoves, ...remainingMoves]
          .map((m) => m.copyWith(isCompleted: false))
          .toList(),
      movesMade: 0,
      progressPercentage: 0,
      correctionComplete: false,
      lastUpdated: DateTime.now(),
      completedMoves: [],
    );
  }

  /// Convertit l'état en JSON
  Map<String, dynamic> toJson() {
    return {
      'currentBooks': currentBooks.map((b) => b.toJson()).toList(),
      'remainingMoves': remainingMoves.map((m) => m.toJson()).toList(),
      'movesMade': movesMade,
      'progressPercentage': progressPercentage,
      'correctionComplete': correctionComplete,
      'lastUpdated': lastUpdated.toIso8601String(),
      'completedMoves': completedMoves.map((m) => m.toJson()).toList(),
    };
  }

  /// Crée un état à partir d'un JSON
  factory ShelfCorrectionState.fromJson(Map<String, dynamic> json) {
    return ShelfCorrectionState(
      currentBooks: (json['currentBooks'] as List)
          .map((b) => ShelfBook.fromJson(b))
          .toList(),
      remainingMoves: (json['remainingMoves'] as List)
          .map((m) => BookMovement.fromJson(m))
          .toList(),
      movesMade: json['movesMade'],
      progressPercentage: json['progressPercentage'],
      correctionComplete: json['correctionComplete'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      completedMoves: (json['completedMoves'] as List?)
              ?.map((m) => BookMovement.fromJson(m))
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'ShelfCorrectionState(progress: ${progressPercentage.toStringAsFixed(0)}%, complete: $correctionComplete)';
}

/// Extension pour firstOrNull (compatible avec Dart < 3.0)
extension ListFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
