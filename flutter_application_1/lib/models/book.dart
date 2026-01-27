/// Modèle représentant un livre dans le système
class Book {
  /// ISBN/Code-barres unique du livre
  final String isbn;

  /// Titre du livre
  final String title;

  /// Auteur du livre
  final String author;

  /// Catégorie/Genre du livre
  final String category;

  /// URL de la couverture du livre
  final String? coverUrl;

  /// Description du livre
  final String? description;

  /// Date et heure du scan (pour compatibilité)
  final DateTime? scannedAt;

  /// Ordre de scan (pour compatibilité)
  final int? order;

  /// Constructeur
  Book({
    required this.isbn,
    required this.title,
    required this.author,
    required this.category,
    this.coverUrl,
    this.description,
    this.scannedAt,
    this.order,
  });

  /// Crée une copie du livre avec des valeurs modifiées
  Book copyWith({
    String? isbn,
    String? title,
    String? author,
    String? category,
    String? coverUrl,
    String? description,
    DateTime? scannedAt,
    int? order,
  }) {
    return Book(
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      scannedAt: scannedAt ?? this.scannedAt,
      order: order ?? this.order,
    );
  }

  /// Convertit o livro em JSON
  Map<String, dynamic> toJson() {
    return {
      'isbn': isbn,
      'title': title,
      'author': author,
      'category': category,
      'coverUrl': coverUrl,
      'description': description,
      'scannedAt': scannedAt?.toIso8601String(),
      'order': order,
    };
  }

  /// Crée un livre à partir d'un JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      isbn: json['isbn'],
      title: json['title'],
      author: json['author'],
      category: json['category'],
      coverUrl: json['coverUrl'],
      description: json['description'],
      scannedAt: json['scannedAt'] != null
          ? DateTime.parse(json['scannedAt'])
          : null,
      order: json['order'],
    );
  }

  /// Convertit le livre en format Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'isbn': isbn,
      'title': title,
      'author': author,
      'category': category,
      'coverUrl': coverUrl,
      'description': description,
      'language': 'fr', // Default language
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Crée un livre à partir d'un document Firestore
  factory Book.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      isbn: data['isbn'] ?? doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      category: data['category'] ?? '',
      coverUrl: data['coverUrl'],
      description: data['description'],
      scannedAt: null, // Not stored in Firestore
      order: null, // Not stored in Firestore
    );
  }

  @override
  String toString() => 'Book(isbn: $isbn, title: $title, author: $author)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && runtimeType == other.runtimeType && isbn == other.isbn;

  @override
  int get hashCode => isbn.hashCode;
}
