import '../models/book.dart';

/// Service de gestion des livres scannés
class BookService {
  final List<Book> _scannedBooks = [];
  int _currentOrder = 1;

  /// Liste de tous les livres scannés (en lecture seule)
  List<Book> get scannedBooks => List.unmodifiable(_scannedBooks);

  /// Nombre total de livres scannés
  int get totalScanned => _scannedBooks.length;

  /// Vérifie si un ISBN/code-barres a déjà été scanné
  bool isBarcodeScanned(String isbn) {
    return _scannedBooks.any((book) => book.isbn == isbn);
  }

  /// Ajoute un nouveau livre à la liste
  /// Retourne le livre créé ou null si déjà scanné
  Book? addBook(
    String isbn, {
    String? title,
    String? author,
    String category = 'Non classé',
  }) {
    if (isBarcodeScanned(isbn)) {
      return null; // Livre déjà scanné
    }

    final book = Book(
      isbn: isbn,
      title: title ?? 'عنوان غير معروف',
      author: author ?? 'مؤلف غير معروف',
      category: category,
      scannedAt: DateTime.now(),
      order: _currentOrder++,
    );

    _scannedBooks.add(book);
    return book;
  }

  /// Supprime un livre par son ISBN/code-barres
  void removeBook(String isbn) {
    _scannedBooks.removeWhere((book) => book.isbn == isbn);
    // Réorganiser les ordres
    _reorderBooks();
  }

  /// Supprime tous les livres scannés
  void clearAll() {
    _scannedBooks.clear();
    _currentOrder = 1;
  }

  void _reorderBooks() {
    if (_scannedBooks.isEmpty) return;
    _scannedBooks.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    for (int i = 0; i < _scannedBooks.length; i++) {
      _scannedBooks[i] = _scannedBooks[i].copyWith(order: i + 1);
    }
    _currentOrder = _scannedBooks.length + 1;
  }

  /// Retourne la liste des livres triés par ordre de scan
  List<Book> getBooksInOrder() {
    return List.from(_scannedBooks)
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  }
}

