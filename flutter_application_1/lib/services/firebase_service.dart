import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library.dart';
import '../models/floor.dart';
import '../models/shelf.dart';
import '../models/book.dart';
import '../models/book_location.dart';

/// Service pour interagir avec Firebase Firestore
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Libraries ====================

  /// Récupère toutes les bibliothèques actives
  Future<List<Library>> getLibraries({String? wilaya}) async {
    try {
      Query query = _firestore.collection('libraries').where('isActive', isEqualTo: true);

      if (wilaya != null && wilaya != 'Tous') {
        query = query.where('wilaya', isEqualTo: wilaya);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Library.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bibliothèques: $e');
    }
  }

  /// Récupère une bibliothèque par ID
  Future<Library?> getLibraryById(String libraryId) async {
    try {
      final doc = await _firestore.collection('libraries').doc(libraryId).get();
      if (!doc.exists) return null;
      return Library.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la bibliothèque: $e');
    }
  }

  /// Crée ou met à jour une bibliothèque (Admin seulement)
  Future<void> saveLibrary(Library library) async {
    try {
      await _firestore.collection('libraries').doc(library.id).set(
        library.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la bibliothèque: $e');
    }
  }

  // ==================== Floors ====================

  /// Récupère tous les étages d'une bibliothèque
  Future<List<Floor>> getFloorsByLibrary(String libraryId) async {
    try {
      final snapshot = await _firestore
          .collection('libraries')
          .doc(libraryId)
          .collection('floors')
          .orderBy('floorNumber')
          .get();

      return snapshot.docs.map((doc) => Floor.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des étages: $e');
    }
  }

  /// Récupère un étage par ID
  Future<Floor?> getFloorById(String libraryId, String floorId) async {
    try {
      final doc = await _firestore
          .collection('libraries')
          .doc(libraryId)
          .collection('floors')
          .doc(floorId)
          .get();

      if (!doc.exists) return null;
      return Floor.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'étage: $e');
    }
  }

  // ==================== Shelves ====================

  /// Récupère tous les rayons d'un étage
  Future<List<Shelf>> getShelvesByFloor(String libraryId, String floorId) async {
    try {
      final snapshot = await _firestore
          .collection('libraries')
          .doc(libraryId)
          .collection('floors')
          .doc(floorId)
          .collection('shelves')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Shelf.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rayons: $e');
    }
  }

  /// Récupère un rayon par ID
  Future<Shelf?> getShelfById(String libraryId, String floorId, String shelfId) async {
    try {
      final doc = await _firestore
          .collection('libraries')
          .doc(libraryId)
          .collection('floors')
          .doc(floorId)
          .collection('shelves')
          .doc(shelfId)
          .get();

      if (!doc.exists) return null;
      return Shelf.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du rayon: $e');
    }
  }

  // ==================== Books ====================

  /// Récupère un livre par ISBN
  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      final doc = await _firestore.collection('books').doc(isbn).get();
      if (!doc.exists) return null;
      return Book.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du livre: $e');
    }
  }

  /// Recherche des livres
  Future<List<Book>> searchBooks(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // For production, consider using Algolia or similar
      final snapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      final allBooks = snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();

      // Client-side filtering (temporary solution)
      final lowerQuery = query.toLowerCase();
      return allBooks.where((book) {
        return book.title.toLowerCase().contains(lowerQuery) ||
            book.author.toLowerCase().contains(lowerQuery) ||
            book.isbn.contains(query);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Récupère les livres par catégorie
  Future<List<Book>> getBooksByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des livres: $e');
    }
  }

  /// Crée ou met à jour un livre (Admin seulement)
  Future<void> saveBook(Book book) async {
    try {
      await _firestore.collection('books').doc(book.isbn).set(
        book.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du livre: $e');
    }
  }

  // ==================== Book Locations ====================

  /// Récupère la localisation d'un livre
  Future<BookLocation?> getBookLocation(String isbn, String libraryId) async {
    try {
      final snapshot = await _firestore
          .collection('bookLocations')
          .where('bookIsbn', isEqualTo: isbn)
          .where('libraryId', isEqualTo: libraryId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return BookLocation.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la localisation: $e');
    }
  }

  /// Récupère tous les livres d'un rayon
  Future<List<BookLocation>> getShelfBooks(String libraryId, String shelfId) async {
    try {
      final snapshot = await _firestore
          .collection('bookLocations')
          .where('libraryId', isEqualTo: libraryId)
          .where('shelfId', isEqualTo: shelfId)
          .orderBy('position')
          .get();

      return snapshot.docs.map((doc) => BookLocation.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des livres du rayon: $e');
    }
  }

  /// Met à jour la position d'un livre
  Future<void> updateBookPosition(BookLocation location) async {
    try {
      // Find existing location document
      final snapshot = await _firestore
          .collection('bookLocations')
          .where('bookIsbn', isEqualTo: location.bookIsbn)
          .where('libraryId', isEqualTo: location.libraryId)
          .where('shelfId', isEqualTo: location.shelfId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update(location.toFirestore());
      } else {
        await _firestore.collection('bookLocations').add(location.toFirestore());
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la position: $e');
    }
  }

  // ==================== Scans ====================

  /// Enregistre un scan
  Future<String> saveScan({
    required String libraryId,
    required String shelfId,
    required String floorId,
    required List<Map<String, dynamic>> scannedBooks,
    String? userId,
  }) async {
    try {
      final scanData = {
        'libraryId': libraryId,
        'shelfId': shelfId,
        'floorId': floorId,
        'scannedBooks': scannedBooks,
        'totalScanned': scannedBooks.length,
        'correctCount': scannedBooks.where((b) => b['isCorrect'] == true).length,
        'errorCount': scannedBooks.where((b) => b['isCorrect'] == false).length,
        'accuracy': scannedBooks.isEmpty
            ? 0.0
            : (scannedBooks.where((b) => b['isCorrect'] == true).length /
                    scannedBooks.length *
                    100),
        'createdAt': FieldValue.serverTimestamp(),
        if (userId != null) 'userId': userId,
      };

      final docRef = await _firestore.collection('scans').add(scanData);
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du scan: $e');
    }
  }

  // ==================== Corrections ====================

  /// Enregistre une correction
  Future<String> saveCorrection({
    required String libraryId,
    required String shelfId,
    required List<Map<String, dynamic>> movements,
    String? userId,
  }) async {
    try {
      final correctionData = {
        'libraryId': libraryId,
        'shelfId': shelfId,
        'status': 'in_progress',
        'totalMoves': movements.length,
        'completedMoves': 0,
        'progressPercentage': 0.0,
        'movements': movements,
        'startedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        if (userId != null) 'userId': userId,
      };

      final docRef = await _firestore.collection('corrections').add(correctionData);
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de la correction: $e');
    }
  }

  /// Met à jour une correction
  Future<void> updateCorrection(String correctionId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('corrections').doc(correctionId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la correction: $e');
    }
  }

  // ==================== Real-time Listeners ====================

  /// Écoute les changements d'une bibliothèque en temps réel
  Stream<Library?> watchLibrary(String libraryId) {
    return _firestore
        .collection('libraries')
        .doc(libraryId)
        .snapshots()
        .map((doc) => doc.exists ? Library.fromFirestore(doc) : null);
  }

  /// Écoute les changements d'un rayon en temps réel
  Stream<Shelf?> watchShelf(String libraryId, String floorId, String shelfId) {
    return _firestore
        .collection('libraries')
        .doc(libraryId)
        .collection('floors')
        .doc(floorId)
        .collection('shelves')
        .doc(shelfId)
        .snapshots()
        .map((doc) => doc.exists ? Shelf.fromFirestore(doc) : null);
  }

  /// Écoute les livres d'un rayon en temps réel
  Stream<List<BookLocation>> watchShelfBooks(String libraryId, String shelfId) {
    return _firestore
        .collection('bookLocations')
        .where('libraryId', isEqualTo: libraryId)
        .where('shelfId', isEqualTo: shelfId)
        .orderBy('position')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookLocation.fromFirestore(doc))
            .toList());
  }
}


