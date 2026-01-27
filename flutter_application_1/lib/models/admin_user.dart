/// Modèle représentant un utilisateur administrateur
class AdminUser {
  /// ID de l'utilisateur (Firebase Auth UID)
  final String id;

  /// Email de l'administrateur
  final String email;

  /// Nom d'affichage
  final String displayName;

  /// Rôle de l'administrateur
  final AdminRole role;

  /// Permissions de l'administrateur
  final AdminPermissions permissions;

  /// Bibliothèques assignées (pour les bibliothécaires)
  final List<String> assignedLibraries;

  /// Indique si le compte est actif
  final bool isActive;

  /// Date de dernière connexion
  final DateTime? lastLoginAt;

  /// Date de création
  final DateTime createdAt;

  /// Date de mise à jour
  final DateTime updatedAt;

  /// ID de l'admin qui a créé ce compte
  final String? createdBy;

  /// Constructeur
  AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.permissions,
    this.assignedLibraries = const [],
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  /// Crée une copie avec des valeurs modifiées
  AdminUser copyWith({
    String? id,
    String? email,
    String? displayName,
    AdminRole? role,
    AdminPermissions? permissions,
    List<String>? assignedLibraries,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      assignedLibraries: assignedLibraries ?? this.assignedLibraries,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Convertit en JSON pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'permissions': permissions.toMap(),
      'assignedLibraries': assignedLibraries,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  /// Crée un AdminUser à partir d'un document Firestore
  factory AdminUser.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: data['id'] ?? doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: AdminRole.fromString(data['role'] ?? 'admin'),
      permissions: AdminPermissions.fromMap(data['permissions'] ?? {}),
      assignedLibraries: List<String>.from(data['assignedLibraries'] ?? []),
      isActive: data['isActive'] ?? true,
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'])
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  /// Vérifie si l'admin a une permission spécifique
  bool hasPermission(String permission) {
    switch (permission) {
      case 'manageLibraries':
        return permissions.canManageLibraries;
      case 'manageBooks':
        return permissions.canManageBooks;
      case 'manageUsers':
        return permissions.canManageUsers;
      case 'viewAnalytics':
        return permissions.canViewAnalytics;
      case 'manageSystem':
        return permissions.canManageSystem;
      default:
        return false;
    }
  }

  /// Vérifie si l'admin peut accéder à une bibliothèque
  bool canAccessLibrary(String libraryId) {
    if (role == AdminRole.superAdmin) return true;
    if (role == AdminRole.admin) return true;
    return assignedLibraries.contains(libraryId);
  }

  @override
  String toString() =>
      'AdminUser(id: $id, email: $email, role: ${role.name}, active: $isActive)';
}

/// Rôles d'administrateur
enum AdminRole {
  superAdmin,
  admin,
  librarian;

  static AdminRole fromString(String value) {
    switch (value) {
      case 'super_admin':
        return AdminRole.superAdmin;
      case 'admin':
        return AdminRole.admin;
      case 'librarian':
        return AdminRole.librarian;
      default:
        return AdminRole.admin;
    }
  }

  String get name {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.admin:
        return 'admin';
      case AdminRole.librarian:
        return 'librarian';
    }
  }

  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Administrateur';
      case AdminRole.admin:
        return 'Administrateur';
      case AdminRole.librarian:
        return 'Bibliothécaire';
    }
  }
}

/// Permissions d'administrateur
class AdminPermissions {
  /// Peut gérer les bibliothèques
  final bool canManageLibraries;

  /// Peut gérer les livres
  final bool canManageBooks;

  /// Peut gérer les utilisateurs
  final bool canManageUsers;

  /// Peut voir les analytics
  final bool canViewAnalytics;

  /// Peut gérer les paramètres système
  final bool canManageSystem;

  /// Constructeur
  AdminPermissions({
    this.canManageLibraries = false,
    this.canManageBooks = false,
    this.canManageUsers = false,
    this.canViewAnalytics = false,
    this.canManageSystem = false,
  });

  /// Crée des permissions par défaut selon le rôle
  factory AdminPermissions.forRole(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AdminPermissions(
          canManageLibraries: true,
          canManageBooks: true,
          canManageUsers: true,
          canViewAnalytics: true,
          canManageSystem: true,
        );
      case AdminRole.admin:
        return AdminPermissions(
          canManageLibraries: true,
          canManageBooks: true,
          canManageUsers: false,
          canViewAnalytics: true,
          canManageSystem: false,
        );
      case AdminRole.librarian:
        return AdminPermissions(
          canManageLibraries: false,
          canManageBooks: true,
          canManageUsers: false,
          canViewAnalytics: true,
          canManageSystem: false,
        );
    }
  }

  /// Convertit en Map
  Map<String, dynamic> toMap() {
    return {
      'canManageLibraries': canManageLibraries,
      'canManageBooks': canManageBooks,
      'canManageUsers': canManageUsers,
      'canViewAnalytics': canViewAnalytics,
      'canManageSystem': canManageSystem,
    };
  }

  /// Crée depuis un Map
  factory AdminPermissions.fromMap(Map<String, dynamic> map) {
    return AdminPermissions(
      canManageLibraries: map['canManageLibraries'] ?? false,
      canManageBooks: map['canManageBooks'] ?? false,
      canManageUsers: map['canManageUsers'] ?? false,
      canViewAnalytics: map['canViewAnalytics'] ?? false,
      canManageSystem: map['canManageSystem'] ?? false,
    );
  }

  /// Crée une copie avec des valeurs modifiées
  AdminPermissions copyWith({
    bool? canManageLibraries,
    bool? canManageBooks,
    bool? canManageUsers,
    bool? canViewAnalytics,
    bool? canManageSystem,
  }) {
    return AdminPermissions(
      canManageLibraries: canManageLibraries ?? this.canManageLibraries,
      canManageBooks: canManageBooks ?? this.canManageBooks,
      canManageUsers: canManageUsers ?? this.canManageUsers,
      canViewAnalytics: canViewAnalytics ?? this.canViewAnalytics,
      canManageSystem: canManageSystem ?? this.canManageSystem,
    );
  }
}


