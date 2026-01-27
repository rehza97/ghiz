import '../models/book.dart';
import '../models/library.dart';
import '../models/floor.dart';
import '../models/shelf.dart';
import '../models/book_location.dart';
import '../models/shelf_book.dart';
import '../models/ips_beacon.dart';

/// Classe contenant toutes les données simulées pour l'application
class MockData {
  /// Bibliothèques simulées
  static final List<Library> libraries = [
    Library(
      id: 'lib_001',
      name: 'Bibliothèque Nationale d\'Algérie',
      address: '1 Rue Docteur Saâdane',
      postalCode: '16000',
      city: 'Alger',
      phone: '+213 21 66 12 34',
      email: 'contact@bna.dz',
      floorCount: 4,
      latitude: 36.7538,
      longitude: 3.0588,
      logoUrl: 'https://example.com/logo.png',
      hours: 'Dim-Jeu: 8h-17h, Ven-Sam: 8h-16h',
      description: 'La plus grande bibliothèque d\'Algérie avec une vaste collection de livres et documents',
    ),
    Library(
      id: 'lib_002',
      name: 'Bibliothèque Municipale d\'Oran',
      address: 'Boulevard de la Soummam',
      postalCode: '31000',
      city: 'Oran',
      phone: '+213 41 33 45 67',
      email: 'info@biblio-oran.dz',
      floorCount: 3,
      latitude: 35.6971,
      longitude: -0.6337,
      logoUrl: 'https://example.com/logo2.png',
      hours: 'Dim-Jeu: 9h-18h, Ven-Sam: 9h-17h',
      description: 'Bibliothèque moderne au cœur d\'Oran, spécialisée en littérature algérienne et francophone',
    ),
    Library(
      id: 'lib_003',
      name: 'Bibliothèque Universitaire de Constantine',
      address: 'Campus Universitaire El Khroub',
      postalCode: '25000',
      city: 'Constantine',
      phone: '+213 31 78 90 12',
      email: 'contact@buc-constantine.dz',
      floorCount: 3,
      latitude: 36.3650,
      longitude: 6.6147,
      logoUrl: 'https://example.com/logo3.png',
      hours: 'Dim-Jeu: 8h-19h, Ven-Sam: 8h-17h',
      description: 'Bibliothèque universitaire avec une riche collection académique et de recherche',
    ),
  ];

  /// Étages simulés
  static final List<Floor> floors = [
    // Étages de la Bibliothèque Nationale d'Algérie
    Floor(
      id: 'floor_001',
      name: 'Rez-de-chaussée',
      floorNumber: 0,
      libraryId: 'lib_001',
      mapAssetPath: 'assets/maps/lib_001_floor_0.svg',
      description: 'Accueil, section jeunesse et livres récents',
      shelfCount: 10,
      mapWidth: 1200,
      mapHeight: 800,
    ),
    Floor(
      id: 'floor_002',
      name: '1er étage',
      floorNumber: 1,
      libraryId: 'lib_001',
      mapAssetPath: 'assets/maps/lib_001_floor_1.svg',
      description: 'Fiction générale, romans algériens et francophones',
      shelfCount: 12,
      mapWidth: 1200,
      mapHeight: 800,
    ),
    Floor(
      id: 'floor_003',
      name: '2ème étage',
      floorNumber: 2,
      libraryId: 'lib_001',
      mapAssetPath: 'assets/maps/lib_001_floor_2.svg',
      description: 'Non-fiction, histoire et références',
      shelfCount: 10,
      mapWidth: 1200,
      mapHeight: 800,
    ),
    Floor(
      id: 'floor_004',
      name: '3ème étage',
      floorNumber: 3,
      libraryId: 'lib_001',
      mapAssetPath: 'assets/maps/lib_001_floor_3.svg',
      description: 'Archives et collections spéciales',
      shelfCount: 8,
      mapWidth: 1200,
      mapHeight: 800,
    ),
    // Étages de la Bibliothèque Municipale d'Oran
    Floor(
      id: 'floor_005',
      name: 'Rez-de-chaussée',
      floorNumber: 0,
      libraryId: 'lib_002',
      mapAssetPath: 'assets/maps/lib_002_floor_0.svg',
      description: 'Accueil et littérature algérienne moderne',
      shelfCount: 8,
      mapWidth: 1000,
      mapHeight: 700,
    ),
    Floor(
      id: 'floor_006',
      name: '1er étage',
      floorNumber: 1,
      libraryId: 'lib_002',
      mapAssetPath: 'assets/maps/lib_002_floor_1.svg',
      description: 'Littérature classique et francophone',
      shelfCount: 10,
      mapWidth: 1000,
      mapHeight: 700,
    ),
    Floor(
      id: 'floor_007',
      name: '2ème étage',
      floorNumber: 2,
      libraryId: 'lib_002',
      mapAssetPath: 'assets/maps/lib_002_floor_2.svg',
      description: 'Sciences, histoire et références',
      shelfCount: 8,
      mapWidth: 1000,
      mapHeight: 700,
    ),
    // Étages de la Bibliothèque Universitaire de Constantine
    Floor(
      id: 'floor_008',
      name: 'Rez-de-chaussée',
      floorNumber: 0,
      libraryId: 'lib_003',
      mapAssetPath: 'assets/maps/lib_003_floor_0.svg',
      description: 'Accueil et ouvrages de référence',
      shelfCount: 6,
      mapWidth: 1000,
      mapHeight: 700,
    ),
    Floor(
      id: 'floor_009',
      name: '1er étage',
      floorNumber: 1,
      libraryId: 'lib_003',
      mapAssetPath: 'assets/maps/lib_003_floor_1.svg',
      description: 'Sciences et technologies',
      shelfCount: 8,
      mapWidth: 1000,
      mapHeight: 700,
    ),
    Floor(
      id: 'floor_010',
      name: '2ème étage',
      floorNumber: 2,
      libraryId: 'lib_003',
      mapAssetPath: 'assets/maps/lib_003_floor_2.svg',
      description: 'Littérature et sciences humaines',
      shelfCount: 8,
      mapWidth: 1000,
      mapHeight: 700,
    ),
  ];

  /// Rayons simulés
  static final List<Shelf> shelves = [
    // Rayons du rez-de-chaussée de la Bibliothèque Nationale d'Algérie
    Shelf(
      id: 'shelf_001',
      name: 'A-1-1',
      floorId: 'floor_001',
      libraryId: 'lib_001',
      x: 2.5,
      y: 1.5,
      z: 0,
      width: 2.0,
      height: 2.5,
      depth: 0.3,
      category: 'Jeunesse',
      capacity: 50,
      currentCount: 48,
      description: 'Livres pour enfants (0-6 ans)',
    ),
    Shelf(
      id: 'shelf_002',
      name: 'A-1-2',
      floorId: 'floor_001',
      libraryId: 'lib_001',
      x: 5.0,
      y: 1.5,
      z: 0,
      width: 2.0,
      height: 2.5,
      depth: 0.3,
      category: 'Jeunesse',
      capacity: 50,
      currentCount: 49,
      description: 'Livres pour enfants (7-12 ans)',
    ),
    Shelf(
      id: 'shelf_003',
      name: 'A-1-3',
      floorId: 'floor_001',
      libraryId: 'lib_001',
      x: 7.5,
      y: 1.5,
      z: 0,
      width: 2.0,
      height: 2.5,
      depth: 0.3,
      category: 'Jeunesse',
      capacity: 50,
      currentCount: 46,
      description: 'Adolescents (13-18 ans)',
    ),
    // Rayons du 1er étage de la Bibliothèque Nationale d'Algérie
    Shelf(
      id: 'shelf_004',
      name: 'B-2-1',
      floorId: 'floor_002',
      libraryId: 'lib_001',
      x: 2.0,
      y: 2.0,
      z: 1,
      width: 2.0,
      height: 2.5,
      depth: 0.3,
      category: 'Fiction',
      capacity: 60,
      currentCount: 58,
      description: 'Romans algériens A-L',
    ),
    Shelf(
      id: 'shelf_005',
      name: 'B-2-2',
      floorId: 'floor_002',
      libraryId: 'lib_001',
      x: 4.5,
      y: 2.0,
      z: 1,
      width: 2.0,
      height: 2.5,
      depth: 0.3,
      category: 'Fiction',
      capacity: 60,
      currentCount: 57,
      description: 'Romans algériens et francophones M-Z',
    ),
    Shelf(
      id: 'shelf_006',
      name: 'B-2-3',
      floorId: 'floor_002',
      libraryId: 'lib_001',
      x: 7.0,
      y: 2.0,
      z: 1,
      width: 2.0,
      height: 2.5,
      depth: 0.3,
      category: 'Fiction',
      capacity: 60,
      currentCount: 55,
      description: 'Romans étrangers',
    ),
  ];

  /// Livres simulés
  static final List<Book> books = [
    Book(
      isbn: '978-2070364008',
      title: 'Le Seigneur des Anneaux',
      author: 'J.R.R. Tolkien',
      category: 'Fantasy',
      coverUrl: 'https://example.com/lotr.jpg',
      description: 'Une épopée fantastique incontournable',
    ),
    Book(
      isbn: '978-2070113018',
      title: '1984',
      author: 'George Orwell',
      category: 'Dystopie',
      coverUrl: 'https://example.com/1984.jpg',
      description: 'Un roman d\'anticipation sombre et troublant',
    ),
    Book(
      isbn: '978-2080701473',
      title: 'Le Seigneur de Brume',
      author: 'J.R.R. Tolkien',
      category: 'Fantasy',
      coverUrl: 'https://example.com/fog.jpg',
      description: 'Une aventure mystérieuse',
    ),
    Book(
      isbn: '978-2070113575',
      title: 'Fondation',
      author: 'Isaac Asimov',
      category: 'Science-Fiction',
      coverUrl: 'https://example.com/foundation.jpg',
      description: 'Une série fondatrice de la SF',
    ),
    Book(
      isbn: '978-2253089698',
      title: 'Orgueil et Préjugés',
      author: 'Jane Austen',
      category: 'Romance Classique',
      coverUrl: 'https://example.com/pride.jpg',
      description: 'Un grand classique de la littérature anglaise',
    ),
    Book(
      isbn: '978-2070117796',
      title: 'Brave New World',
      author: 'Aldous Huxley',
      category: 'Dystopie',
      coverUrl: 'https://example.com/bnw.jpg',
      description: 'Un futur dystopique et séduisant',
    ),
    Book(
      isbn: '978-2253046738',
      title: 'Le Comte de Monte Cristo',
      author: 'Alexandre Dumas',
      category: 'Aventure Classique',
      coverUrl: 'https://example.com/monte_cristo.jpg',
      description: 'Une histoire de vengeance et de rédemption',
    ),
    Book(
      isbn: '978-2259201414',
      title: 'Les Misérables',
      author: 'Victor Hugo',
      category: 'Classique Français',
      coverUrl: 'https://example.com/les_miserables.jpg',
      description: 'L\'épopée française par excellence',
    ),
    Book(
      isbn: '978-2080808788',
      title: 'Jane Eyre',
      author: 'Charlotte Brontë',
      category: 'Romance Classique',
      coverUrl: 'https://example.com/jane_eyre.jpg',
      description: 'Un classique intemporel d\'amour et d\'indépendance',
    ),
    Book(
      isbn: '978-2070119943',
      title: 'Dune',
      author: 'Frank Herbert',
      category: 'Science-Fiction',
      coverUrl: 'https://example.com/dune.jpg',
      description: 'Une épopée de science-fiction majeure',
    ),
  ];

  /// Localisations des livres
  static final List<BookLocation> bookLocations = [
    BookLocation(
      bookIsbn: '978-2070364008',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_004',
      // Simplified test positions: 1, 2, 3 on the same shelf
      position: 1,
      expectedPosition: 1,
      isCorrectOrder: true,
      isFlagged: false,
    ),
    BookLocation(
      bookIsbn: '978-2070113018',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_004',
      position: 2,
      expectedPosition: 2,
      isCorrectOrder: true,
      isFlagged: false,
    ),
    BookLocation(
      bookIsbn: '978-2080701473',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_004',
      position: 3,
      expectedPosition: 3,
      isCorrectOrder: true,
      isFlagged: false,
    ),
    BookLocation(
      bookIsbn: '978-2070113575',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_005',
      position: 2,
      expectedPosition: 2,
      isCorrectOrder: true,
    ),
    BookLocation(
      bookIsbn: '978-2253089698',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_005',
      position: 15,
      expectedPosition: 10,
      isCorrectOrder: false,
      isFlagged: true,
      reason: 'Livre trop décalé à droite',
      misplacementCount: 3,
    ),
    BookLocation(
      bookIsbn: '978-2070117796',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_005',
      position: 10,
      expectedPosition: 10,
      isCorrectOrder: true,
    ),
    BookLocation(
      bookIsbn: '978-2253046738',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_006',
      position: 20,
      expectedPosition: 15,
      isCorrectOrder: false,
      isFlagged: true,
      reason: 'Livre mal classé',
      misplacementCount: 2,
    ),
    BookLocation(
      bookIsbn: '978-2259201414',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_006',
      position: 7,
      expectedPosition: 7,
      isCorrectOrder: true,
    ),
    BookLocation(
      bookIsbn: '978-2080808788',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_006',
      position: 25,
      expectedPosition: 25,
      isCorrectOrder: true,
    ),
    BookLocation(
      bookIsbn: '978-2070119943',
      libraryId: 'lib_001',
      floorId: 'floor_002',
      shelfId: 'shelf_006',
      position: 30,
      expectedPosition: 30,
      isCorrectOrder: true,
    ),
  ];

  /// Balises IPS simulées
  static final List<IPSBeacon> ipsBeacons = [
    IPSBeacon(
      id: 'beacon_001',
      uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
      txPower: -55,
      x: 2.5,
      y: 1.5,
      z: 1.5,
      floorId: 'floor_002',
      libraryId: 'lib_001',
      coverageRadius: 15.0,
      location: 'Rayon A-2-1',
    ),
    IPSBeacon(
      id: 'beacon_002',
      uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647826',
      txPower: -55,
      x: 5.0,
      y: 2.0,
      z: 1.5,
      floorId: 'floor_002',
      libraryId: 'lib_001',
      coverageRadius: 15.0,
      location: 'Rayon A-2-2',
    ),
    IPSBeacon(
      id: 'beacon_003',
      uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647827',
      txPower: -55,
      x: 7.5,
      y: 2.5,
      z: 1.5,
      floorId: 'floor_002',
      libraryId: 'lib_001',
      coverageRadius: 15.0,
      location: 'Rayon A-2-3',
    ),
  ];

  /// Obtient une bibliothèque par ID
  static Library? getLibraryById(String id) {
    try {
      return libraries.firstWhere((lib) => lib.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient tous les étages d'une bibliothèque
  static List<Floor> getFloorsByLibrary(String libraryId) {
    return floors.where((floor) => floor.libraryId == libraryId).toList();
  }

  /// Obtient un étage par ID
  static Floor? getFloorById(String id) {
    try {
      return floors.firstWhere((floor) => floor.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient tous les rayons d'un étage
  static List<Shelf> getShelvesByFloor(String floorId) {
    return shelves.where((shelf) => shelf.floorId == floorId).toList();
  }

  /// Obtient un rayon par ID
  static Shelf? getShelfById(String id) {
    try {
      return shelves.firstWhere((shelf) => shelf.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtient un livre par ISBN
  static Book? getBookByIsbn(String isbn) {
    try {
      return books.firstWhere((book) => book.isbn == isbn);
    } catch (e) {
      return null;
    }
  }

  /// Obtient tous les livres d'une catégorie
  static List<Book> getBooksByCategory(String category) {
    return books.where((book) => book.category == category).toList();
  }

  /// Obtient la localisation d'un livre
  static BookLocation? getBookLocation(String isbn) {
    try {
      return bookLocations.firstWhere((loc) => loc.bookIsbn == isbn);
    } catch (e) {
      return null;
    }
  }

  /// Obtient tous les livres d'un rayon
  static List<ShelfBook> getShelfBooks(String shelfId, String libraryId) {
    final locs = bookLocations
        .where((loc) => loc.shelfId == shelfId && loc.libraryId == libraryId)
        .toList();

    return locs.map((loc) {
      final book = getBookByIsbn(loc.bookIsbn)!;
      return ShelfBook(
        book: book,
        currentPosition: loc.position,
        expectedPosition: loc.expectedPosition,
        barcode: book.isbn,
        isCorrect: loc.isCorrectOrder,
        deviation: (loc.expectedPosition - loc.position).abs(),
        movementDirection:
            loc.position < loc.expectedPosition ? 'droite' : 'gauche',
      );
    }).toList();
  }

  /// Obtient les balises IPS d'un étage
  static List<IPSBeacon> getBeaconsByFloor(String floorId) {
    return ipsBeacons.where((beacon) => beacon.floorId == floorId).toList();
  }

  /// Recherche des livres par titre
  static List<Book> searchBooks(String query) {
    final lowerQuery = query.toLowerCase();
    return books
        .where((book) =>
            book.title.toLowerCase().contains(lowerQuery) ||
            book.author.toLowerCase().contains(lowerQuery) ||
            book.isbn.contains(query))
        .toList();
  }
}
