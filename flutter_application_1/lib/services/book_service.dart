import '../models/book.dart';
import 'firebase_service.dart';

/// Service de gestion des livres scannés, backed by local SQLite.
class BookService {
  final FirebaseService _firebase = FirebaseService();
  final List<Book> _scannedBooks = [];
  int _currentOrder = 1;

  BookService() {
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    final books = await _firebase.searchBooks('');
    _scannedBooks
      ..clear()
      ..addAll(
        books
            .where((book) => book.scannedAt != null || (book.order ?? 0) > 0)
            .toList()
          ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0)),
      );
    _currentOrder = _scannedBooks.length + 1;
  }

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
    _firebase.saveBook(book);
    return book;
  }

  /// Supprime un livre par son ISBN/code-barres
  void removeBook(String isbn) {
    _scannedBooks.removeWhere((book) => book.isbn == isbn);
    _firebase.deleteBook(isbn);
    // Réorganiser les ordres
    _reorderBooks();
  }

  /// Supprime tous les livres scannés
  void clearAll() {
    for (final book in _scannedBooks) {
      _firebase.deleteBook(book.isbn);
    }
    _scannedBooks.clear();
    _currentOrder = 1;
  }

  void _reorderBooks() {
    if (_scannedBooks.isEmpty) return;
    _scannedBooks.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    for (int i = 0; i < _scannedBooks.length; i++) {
      _scannedBooks[i] = _scannedBooks[i].copyWith(order: i + 1);
      _firebase.saveBook(_scannedBooks[i]);
    }
    _currentOrder = _scannedBooks.length + 1;
  }

  /// Retourne la liste des livres triés par ordre de scan
  List<Book> getBooksInOrder() {
    return List.from(_scannedBooks)
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
  }
}
