/// Modèle représentant une balise IPS (Indoor Positioning System) Bluetooth
class IPSBeacon {
  /// Identifiant unique de la balise
  final String id;

  /// UUID de la balise BLE
  final String uuid;

  /// Puissance d'émission de la balise (RSSI à 1 mètre)
  final int txPower;

  /// Position X de la balise (en mètres)
  final double x;

  /// Position Y de la balise (en mètres)
  final double y;

  /// Position Z (hauteur)
  final double z;

  /// Identifiant de l'étage où se trouve la balise
  final String floorId;

  /// Identifiant de la bibliothèque
  final String libraryId;

  /// Zone de couverture de la balise (rayon en mètres)
  final double coverageRadius;

  /// Description du lieu de la balise
  final String? location;

  /// Constructeur
  IPSBeacon({
    required this.id,
    required this.uuid,
    required this.txPower,
    required this.x,
    required this.y,
    required this.z,
    required this.floorId,
    required this.libraryId,
    required this.coverageRadius,
    this.location,
  });

  /// Crée une copie avec des valeurs modifiées
  IPSBeacon copyWith({
    String? id,
    String? uuid,
    int? txPower,
    double? x,
    double? y,
    double? z,
    String? floorId,
    String? libraryId,
    double? coverageRadius,
    String? location,
  }) {
    return IPSBeacon(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      txPower: txPower ?? this.txPower,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      floorId: floorId ?? this.floorId,
      libraryId: libraryId ?? this.libraryId,
      coverageRadius: coverageRadius ?? this.coverageRadius,
      location: location ?? this.location,
    );
  }

  /// Calcule la distance estimée basée sur la puissance du signal (RSSI)
  /// En utilisant le modèle de propagation de Friis
  double estimatedDistance(int measuredRssi) {
    final distance = pow(10, ((txPower - measuredRssi) / (10 * 2)).toDouble());
    return distance;
  }

  /// Convertit la balise en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'txPower': txPower,
      'x': x,
      'y': y,
      'z': z,
      'floorId': floorId,
      'libraryId': libraryId,
      'coverageRadius': coverageRadius,
      'location': location,
    };
  }

  /// Crée une balise à partir d'un JSON
  factory IPSBeacon.fromJson(Map<String, dynamic> json) {
    return IPSBeacon(
      id: json['id'],
      uuid: json['uuid'],
      txPower: json['txPower'],
      x: json['x'],
      y: json['y'],
      z: json['z'],
      floorId: json['floorId'],
      libraryId: json['libraryId'],
      coverageRadius: json['coverageRadius'],
      location: json['location'],
    );
  }

  @override
  String toString() =>
      'IPSBeacon(id: $id, location: $location, uuid: ${uuid.substring(0, 8)}...)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IPSBeacon && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Helper function for pow since we're not importing dart:math here
double pow(num base, num exponent) {
  return base * (exponent > 1 ? pow(base, exponent - 1) : 1);
}
