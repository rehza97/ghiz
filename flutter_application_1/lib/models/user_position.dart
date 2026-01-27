import 'dart:math';
import 'book_ar_data.dart';

/// Modèle représentant la position actuelle de l'utilisateur
class UserPosition {
  /// Coordonnées GPS
  final LatLng gpsCoordinate;

  /// Identifiant de l'étage sur lequel se trouve l'utilisateur
  final String floorId;

  /// Position X intérieure (en mètres)
  final double indoorX;

  /// Position Y intérieure (en mètres)
  final double indoorY;

  /// Précision de la position (en mètres)
  final double accuracy;

  /// Orientation/direction de l'utilisateur (en degrés, 0-360)
  final double heading;

  /// Orientation de la caméra (en degrés)
  final double? cameraAngle;

  /// Timestamp de la dernière mise à jour
  final DateTime lastUpdated;

  /// Indique si la position est fiable
  final bool isReliable;

  /// Constructeur
  UserPosition({
    required this.gpsCoordinate,
    required this.floorId,
    required this.indoorX,
    required this.indoorY,
    required this.accuracy,
    required this.heading,
    this.cameraAngle,
    required this.lastUpdated,
    required this.isReliable,
  });

  /// Crée une copie avec des valeurs modifiées
  UserPosition copyWith({
    LatLng? gpsCoordinate,
    String? floorId,
    double? indoorX,
    double? indoorY,
    double? accuracy,
    double? heading,
    double? cameraAngle,
    DateTime? lastUpdated,
    bool? isReliable,
  }) {
    return UserPosition(
      gpsCoordinate: gpsCoordinate ?? this.gpsCoordinate,
      floorId: floorId ?? this.floorId,
      indoorX: indoorX ?? this.indoorX,
      indoorY: indoorY ?? this.indoorY,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      cameraAngle: cameraAngle ?? this.cameraAngle,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isReliable: isReliable ?? this.isReliable,
    );
  }

  /// Calcule la distance entre la position actuelle et une autre position
  double distanceTo(UserPosition other) {
    final dx = other.indoorX - indoorX;
    final dy = other.indoorY - indoorY;
    return sqrt(dx * dx + dy * dy);
  }

  /// Convertit la position en JSON
  Map<String, dynamic> toJson() {
    return {
      'gpsCoordinate': {
        'latitude': gpsCoordinate.latitude,
        'longitude': gpsCoordinate.longitude,
      },
      'floorId': floorId,
      'indoorX': indoorX,
      'indoorY': indoorY,
      'accuracy': accuracy,
      'heading': heading,
      'cameraAngle': cameraAngle,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isReliable': isReliable,
    };
  }

  /// Crée une position à partir d'un JSON
  factory UserPosition.fromJson(Map<String, dynamic> json) {
    final gpsData = json['gpsCoordinate'] as Map<String, dynamic>;
    return UserPosition(
      gpsCoordinate: LatLng(
        latitude: gpsData['latitude'],
        longitude: gpsData['longitude'],
      ),
      floorId: json['floorId'],
      indoorX: json['indoorX'],
      indoorY: json['indoorY'],
      accuracy: json['accuracy'],
      heading: json['heading'],
      cameraAngle: json['cameraAngle'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isReliable: json['isReliable'],
    );
  }

  @override
  String toString() =>
      'UserPosition(floor: $floorId, x: ${indoorX.toStringAsFixed(2)}, y: ${indoorY.toStringAsFixed(2)}, accuracy: ${accuracy.toStringAsFixed(2)}m)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPosition &&
          runtimeType == other.runtimeType &&
          indoorX == other.indoorX &&
          indoorY == other.indoorY &&
          floorId == other.floorId;

  @override
  int get hashCode => Object.hash(indoorX, indoorY, floorId);
}
