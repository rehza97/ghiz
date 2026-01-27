import 'book.dart';
import 'book_location.dart';
import 'shelf.dart';

/// Énumération des statuts de badge pour l'affichage AR
enum BadgeStatus {
  /// Le livre est à la bonne position
  correct,

  /// Le livre est sur le bon rayon mais à la mauvaise position
  wrongPosition,

  /// Le livre est sur un rayon complètement différent
  wrongShelf,

  /// Plusieurs copies du même livre détectées
  duplicate,

  /// Statut inconnu
  unknown,
}

/// Modèle pour l'affichage AR des informations de livre
class BookARData {
  /// Le livre détecté
  final Book book;

  /// Localisation du livre
  final BookLocation location;

  /// Informations du rayon
  final Shelf shelf;

  /// Données de positionnement 3D du rayon
  final ShelfPosition shelfPosition;

  /// Contenu de l'overlay AR
  final ArOverlay arOverlay;

  /// Indique si le livre est à la bonne position
  final bool isInCorrectOrder;

  /// Position actuelle du livre sur le rayon
  final int currentPosition;

  /// Position attendue du livre
  final int expectedPosition;

  /// Distance du livre par rapport à l'utilisateur (en mètres)
  final double distanceToUser;

  /// Constructeur
  BookARData({
    required this.book,
    required this.location,
    required this.shelf,
    required this.shelfPosition,
    required this.arOverlay,
    required this.isInCorrectOrder,
    required this.currentPosition,
    required this.expectedPosition,
    required this.distanceToUser,
  });

  /// Crée une copie avec des valeurs modifiées
  BookARData copyWith({
    Book? book,
    BookLocation? location,
    Shelf? shelf,
    ShelfPosition? shelfPosition,
    ArOverlay? arOverlay,
    bool? isInCorrectOrder,
    int? currentPosition,
    int? expectedPosition,
    double? distanceToUser,
  }) {
    return BookARData(
      book: book ?? this.book,
      location: location ?? this.location,
      shelf: shelf ?? this.shelf,
      shelfPosition: shelfPosition ?? this.shelfPosition,
      arOverlay: arOverlay ?? this.arOverlay,
      isInCorrectOrder: isInCorrectOrder ?? this.isInCorrectOrder,
      currentPosition: currentPosition ?? this.currentPosition,
      expectedPosition: expectedPosition ?? this.expectedPosition,
      distanceToUser: distanceToUser ?? this.distanceToUser,
    );
  }

  @override
  String toString() =>
      'BookARData(title: ${book.title}, position: $currentPosition/$expectedPosition, correct: $isInCorrectOrder)';
}

/// Données de positionnement 3D du rayon
class ShelfPosition {
  /// Identifiant unique du rayon
  final String shelfId;

  /// Position X du centre du rayon (en mètres)
  final double x;

  /// Position Y du centre du rayon (en mètres)
  final double y;

  /// Position Z (hauteur/étage en mètres)
  final double z;

  /// Largeur du rayon (en mètres)
  final double width;

  /// Hauteur du rayon (en mètres)
  final double height;

  /// Profondeur du rayon (en mètres)
  final double depth;

  /// Coordonnée GPS du rayon
  final LatLng gpsCoordinate;

  /// Distance du rayon par rapport à l'utilisateur (calculée)
  final double distanceToUser;

  /// Coin supérieur gauche du rayon
  final Vector3 topLeft;

  /// Coin supérieur droit du rayon
  final Vector3 topRight;

  /// Coin inférieur gauche du rayon
  final Vector3 bottomLeft;

  /// Coin inférieur droit du rayon
  final Vector3 bottomRight;

  /// Constructeur
  ShelfPosition({
    required this.shelfId,
    required this.x,
    required this.y,
    required this.z,
    required this.width,
    required this.height,
    required this.depth,
    required this.gpsCoordinate,
    required this.distanceToUser,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  String toString() =>
      'ShelfPosition(id: $shelfId, distance: ${distanceToUser.toStringAsFixed(2)}m)';
}

/// Contenu de l'overlay AR
class ArOverlay {
  /// Code-barres du livre
  final String bookBarcode;

  /// Titre du livre
  final String bookTitle;

  /// Auteur du livre
  final String bookAuthor;

  /// URL de la couverture du livre
  final String? bookCover;

  /// Statut du badge
  final BadgeStatus status;

  /// Message à afficher
  final String statusMessage;

  /// Couleur du badge
  final int statusColor; // RGB as int

  /// Liste des coins du rayon en 3D
  final List<Vector3> shelfBoundary;

  /// Position du badge à l'écran (x, y) comme Map
  final Map<String, double>? screenPosition;

  /// Taille du badge (width, height)
  final Map<String, double> badgeSize;

  /// Constructeur
  ArOverlay({
    required this.bookBarcode,
    required this.bookTitle,
    required this.bookAuthor,
    this.bookCover,
    required this.status,
    required this.statusMessage,
    required this.statusColor,
    required this.shelfBoundary,
    this.screenPosition,
    this.badgeSize = const {'width': 300, 'height': 200},
  });

  /// Obtient la couleur du badge au format Color
  int get colorValue {
    switch (status) {
      case BadgeStatus.correct:
        return 0xFF4CAF50; // Vert
      case BadgeStatus.wrongPosition:
        return 0xFFFFC107; // Jaune/Orange
      case BadgeStatus.wrongShelf:
        return 0xFFF44336; // Rouge
      case BadgeStatus.duplicate:
        return 0xFF9C27B0; // Violet
      case BadgeStatus.unknown:
        return 0xFF757575; // Gris
    }
  }

  /// Obtient le symbole du badge
  String get badgeSymbol {
    switch (status) {
      case BadgeStatus.correct:
        return '✓';
      case BadgeStatus.wrongPosition:
        return '⚠';
      case BadgeStatus.wrongShelf:
        return '✗';
      case BadgeStatus.duplicate:
        return '⚠⚠';
      case BadgeStatus.unknown:
        return '?';
    }
  }

  /// Crée une copie avec des valeurs modifiées
  ArOverlay copyWith({
    String? bookBarcode,
    String? bookTitle,
    String? bookAuthor,
    String? bookCover,
    BadgeStatus? status,
    String? statusMessage,
    int? statusColor,
    List<Vector3>? shelfBoundary,
    Map<String, double>? screenPosition,
    Map<String, double>? badgeSize,
  }) {
    return ArOverlay(
      bookBarcode: bookBarcode ?? this.bookBarcode,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      bookCover: bookCover ?? this.bookCover,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      statusColor: statusColor ?? this.statusColor,
      shelfBoundary: shelfBoundary ?? this.shelfBoundary,
      screenPosition: screenPosition ?? this.screenPosition,
      badgeSize: badgeSize ?? this.badgeSize,
    );
  }

  @override
  String toString() =>
      'ArOverlay(title: $bookTitle, status: $status, message: $statusMessage)';
}

/// Classe pour représenter un vecteur 3D
class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3({required this.x, required this.y, required this.z});

  @override
  String toString() => 'Vector3(x: $x, y: $y, z: $z)';
}

/// Classe pour représenter une coordonnée GPS
class LatLng {
  final double latitude;
  final double longitude;

  LatLng({required this.latitude, required this.longitude});

  @override
  String toString() => 'LatLng(lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
