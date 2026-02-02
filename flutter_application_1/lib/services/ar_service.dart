import '../models/book.dart';
import '../models/book_location.dart';
import '../models/book_ar_data.dart';
import '../models/shelf.dart';
import '../models/shelf_book.dart';
import '../models/book_movement.dart';
import '../models/book_correction_guide.dart';

/// Service pour gérer la logique AR et la détection des livres
class ARService {
  /// Génère les données AR pour un livre détecté
  BookARData generateBookARData({
    required Book book,
    required BookLocation location,
    required Shelf shelf,
    required double distanceToUser,
    required double cameraAngle,
  }) {
    // Déterminer le statut du badge
    late BadgeStatus status;
    late String statusMessage;

    if (location.isCorrectOrder) {
      status = BadgeStatus.correct;
      statusMessage = 'في المكان الصحيح ✓';
    } else {
      final deviation = location.positionDeviation;
      if (deviation >= 3) {
        status = BadgeStatus.wrongPosition;
        statusMessage =
            'يجب أن يكون في الموقع ${location.expectedPosition}';
      } else {
        status = BadgeStatus.wrongPosition;
        statusMessage =
            'الموقع ${location.position}/${location.expectedPosition}';
      }
    }

    // Créer la position 3D du rayon
    final shelfPosition = ShelfPosition(
      shelfId: shelf.id,
      x: shelf.x,
      y: shelf.y,
      z: shelf.z,
      width: shelf.width,
      height: shelf.height,
      depth: shelf.depth,
      gpsCoordinate: _mockGpsFromPosition(shelf.x, shelf.y),
      distanceToUser: distanceToUser,
      topLeft: Vector3(x: shelf.x - shelf.width / 2, y: shelf.y, z: shelf.z + shelf.height),
      topRight: Vector3(x: shelf.x + shelf.width / 2, y: shelf.y, z: shelf.z + shelf.height),
      bottomLeft: Vector3(x: shelf.x - shelf.width / 2, y: shelf.y, z: shelf.z),
      bottomRight: Vector3(x: shelf.x + shelf.width / 2, y: shelf.y, z: shelf.z),
    );

    // Créer l'overlay AR
    final arOverlay = ArOverlay(
      bookBarcode: book.isbn,
      bookTitle: book.title,
      bookAuthor: book.author,
      bookCover: book.coverUrl,
      status: status,
      statusMessage: statusMessage,
      statusColor: _getStatusColor(status),
      shelfBoundary: _generateShelfBoundary(shelfPosition),
      badgeSize: const {'width': 320, 'height': 200},
    );

    return BookARData(
      book: book,
      location: location,
      shelf: shelf,
      shelfPosition: shelfPosition,
      arOverlay: arOverlay,
      isInCorrectOrder: location.isCorrectOrder,
      currentPosition: location.position,
      expectedPosition: location.expectedPosition,
      distanceToUser: distanceToUser,
    );
  }

  /// Calcule les mouvements requis pour corriger l'ordre des livres
  BookCorrectionGuide calculateCorrectionGuide({
    required List<ShelfBook> detectedBooks,
    required List<ShelfBook> expectedBooks,
    String? shelfId,
  }) {
    final requiredMoves = <BookMovement>[];
    var totalErrors = 0;

    // Parcourir les livres détectés et comparer avec l'ordre attendu
    for (var book in detectedBooks) {
      if (!book.isCorrect) {
        totalErrors++;

        final moveDirection = book.expectedPosition > book.currentPosition
            ? MovementDirection.right
            : MovementDirection.left;

        final distance =
            (book.expectedPosition - book.currentPosition).abs();
        final priority = _calculatePriority(distance);

        requiredMoves.add(
          BookMovement(
            bookBarcode: book.barcode,
            bookTitle: book.book.title,
            fromPosition: book.currentPosition,
            toPosition: book.expectedPosition,
            direction: moveDirection,
            distance: distance,
            priority: priority,
            instruction: _generateMovementInstruction(
              book.book.title,
              book.currentPosition,
              book.expectedPosition,
              moveDirection,
              distance,
            ),
          ),
        );
      }
    }

    // Trier les mouvements par priorité
    requiredMoves.sort((a, b) => a.priority.compareTo(b.priority));

    final isInCorrectOrder = requiredMoves.isEmpty;
    final misplacedCount = detectedBooks.where((b) => !b.isCorrect).length;

    return BookCorrectionGuide(
      currentOrder: detectedBooks,
      expectedOrder: expectedBooks,
      requiredMoves: requiredMoves,
      isInCorrectOrder: isInCorrectOrder,
      totalErrorsFound: totalErrors,
      misplacedBooksCount: misplacedCount,
      generatedAt: DateTime.now(),
      shelfId: shelfId,
    );
  }

  /// Génère une liste complète de livres AR pour un rayon
  List<BookARData> generateShelfARView({
    required List<ShelfBook> detectedBooks,
    required Book Function(String isbn) getBook,
    required BookLocation Function(String isbn) getLocation,
    required Shelf shelf,
    required double distanceToShelf,
  }) {
    return detectedBooks.map((shelfBook) {
      final location = getLocation(shelfBook.barcode);

      return generateBookARData(
        book: shelfBook.book,
        location: location,
        shelf: shelf,
        distanceToUser: distanceToShelf,
        cameraAngle: 0, // À implémenter avec les données réelles du capteur
      );
    }).toList();
  }

  /// Vérifie si un code-barres est correctement positionné
  bool isBookInCorrectPosition({
    required String barcode,
    required int currentPosition,
    required int expectedPosition,
  }) {
    return currentPosition == expectedPosition;
  }

  /// Calcule le pourcentage d'exactitude d'un rayon
  double calculateShelfAccuracy(List<ShelfBook> books) {
    if (books.isEmpty) return 100.0;
    final correctCount = books.where((b) => b.isCorrect).length;
    return (correctCount / books.length) * 100;
  }

  /// Génère un guide visuel pour corriger les livres
  List<Map<String, dynamic>> generateCorrectionVisualGuide(
    List<BookMovement> movements,
  ) {
    return movements.map((move) {
      return {
        'bookTitle': move.bookTitle,
        'currentPosition': move.fromPosition,
        'targetPosition': move.toPosition,
        'direction': move.directionSymbol,
        'distance': move.distance,
        'instruction': move.instruction,
        'priority': move.priorityDescription,
        'color': _getPriorityColor(move.priority),
      };
    }).toList();
  }

  /// Privé: Calcule la priorité basée sur la déviation
  int _calculatePriority(int distance) {
    if (distance >= 5) return 0;
    if (distance >= 3) return 1;
    if (distance >= 2) return 2;
    return 3;
  }

  /// يولد تعليمة الحركة
  String _generateMovementInstruction(
    String title,
    int from,
    int to,
    MovementDirection direction,
    int distance,
  ) {
    final directionText = direction == MovementDirection.right
        ? 'اليمين'
        : direction == MovementDirection.left
            ? 'اليسار'
            : 'لأعلى';
    return 'نقل "$title" إلى $directionText ($distance مواقع)';
  }

  /// Privé: Obtient la couleur du statut
  int _getStatusColor(BadgeStatus status) {
    switch (status) {
      case BadgeStatus.correct:
        return 0xFF4CAF50; // Vert
      case BadgeStatus.wrongPosition:
        return 0xFFFFC107; // Orange
      case BadgeStatus.wrongShelf:
        return 0xFFF44336; // Rouge
      case BadgeStatus.duplicate:
        return 0xFF9C27B0; // Violet
      case BadgeStatus.unknown:
        return 0xFF757575; // Gris
    }
  }

  /// Privé: Obtient la couleur basée sur la priorité
  int _getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return 0xFFF44336; // Rouge - Critique
      case 1:
        return 0xFFFF5722; // Orange foncé - Élevé
      case 2:
        return 0xFFFFC107; // Orange - Moyen
      case 3:
        return 0xFF4CAF50; // Vert - Normal
      default:
        return 0xFF2196F3; // Bleu - Faible
    }
  }

  /// Privé: Génère les limites 3D du rayon
  List<Vector3> _generateShelfBoundary(ShelfPosition pos) {
    return [
      pos.topLeft,
      pos.topRight,
      pos.bottomRight,
      pos.bottomLeft,
    ];
  }

  /// Privé: Crée des coordonnées GPS simulées
  LatLng _mockGpsFromPosition(double x, double y) {
    // Simuler des coordonnées GPS basées sur la position locale
    const baseLatitude = 48.8566;
    const baseLongitude = 2.3522;
    const metersPerDegree = 111320;

    return LatLng(
      latitude: baseLatitude + (y / metersPerDegree),
      longitude: baseLongitude + (x / metersPerDegree),
    );
  }
}
