import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'local_database_service.dart';

class DevDatabaseSeedSummary {
  const DevDatabaseSeedSummary({
    required this.libraries,
    required this.floors,
    required this.shelves,
    required this.books,
    required this.locations,
    required this.scans,
    required this.corrections,
    required this.labels,
  });

  final int libraries;
  final int floors;
  final int shelves;
  final int books;
  final int locations;
  final int scans;
  final int corrections;
  final int labels;

  @override
  String toString() {
    return 'libraries=$libraries, floors=$floors, shelves=$shelves, '
        'books=$books, locations=$locations, scans=$scans, '
        'corrections=$corrections, labels=$labels';
  }
}

class DevDatabaseSeedService {
  Future<DevDatabaseSeedSummary> seedFullDatabase({
    int bookCount = 1200,
    int floorCount = 4,
    int shelvesPerFloor = 12,
    double misplacedRate = 0.2,
  }) async {
    final random = Random(DateTime.now().microsecondsSinceEpoch);
    final db = await LocalDatabaseService.instance.database;

    if (bookCount < 100) bookCount = 100;
    if (floorCount < 1) floorCount = 1;
    if (shelvesPerFloor < 2) shelvesPerFloor = 2;
    if (misplacedRate < 0) misplacedRate = 0;
    if (misplacedRate > 0.9) misplacedRate = 0.9;

    final libraryId = 'lib_seed_main';
    final libraryName = 'Bibliotheque Test Reality';
    final shelfCount = floorCount * shelvesPerFloor;
    final perShelf = bookCount ~/ shelfCount;
    final remainder = bookCount % shelfCount;

    final floors = <Map<String, Object?>>[];
    final shelves = <Map<String, Object?>>[];
    final shelfRefs =
        <({String id, String floorId, int capacity, int targetCount})>[];

    for (int f = 0; f < floorCount; f++) {
      final floorId = 'floor_seed_${f + 1}';
      floors.add({
        'id': floorId,
        'name': f == 0 ? 'RDC' : 'Etage $f',
        'floorNumber': f,
        'libraryId': libraryId,
        'mapAssetPath': null,
        'description': 'Etage de test ${f + 1}',
        'shelfCount': shelvesPerFloor,
        'mapWidth': 1200.0,
        'mapHeight': 900.0,
      });

      for (int s = 0; s < shelvesPerFloor; s++) {
        final index = f * shelvesPerFloor + s;
        final count = perShelf + (index < remainder ? 1 : 0);
        final capacity = max(40, count + 20);
        final shelfId = 'shelf_seed_${f + 1}_${s + 1}';
        shelfRefs.add((
          id: shelfId,
          floorId: floorId,
          capacity: capacity,
          targetCount: count,
        ));
        shelves.add({
          'id': shelfId,
          'name': 'R-${f + 1}-${s + 1}',
          'floorId': floorId,
          'libraryId': libraryId,
          'x': (s * 2.0) % 20,
          'y': (f * 3.0) + ((s % 4) * 0.7),
          'z': f.toDouble(),
          'width': 2.0,
          'height': 2.5,
          'depth': 0.35,
          'category': _categories[(index) % _categories.length],
          'capacity': capacity,
          'currentCount': count,
          'description': 'Rayon test ${f + 1}-${s + 1}',
        });
      }
    }

    final books = <Map<String, Object?>>[];
    final locations = <Map<String, Object?>>[];

    // Build a balanced shelf assignment then shuffle so search results are not
    // clustered in the first shelf (e.g. R-1-1).
    final shelfAssignments = <int>[];
    for (int i = 0; i < shelfRefs.length; i++) {
      for (int c = 0; c < shelfRefs[i].targetCount; c++) {
        shelfAssignments.add(i);
      }
    }
    shelfAssignments.shuffle(random);

    final shelfPositionById = <String, int>{
      for (final shelf in shelfRefs) shelf.id: 0,
    };

    for (
      int bookGlobalIndex = 1;
      bookGlobalIndex <= shelfAssignments.length;
      bookGlobalIndex++
    ) {
      final shelf = shelfRefs[shelfAssignments[bookGlobalIndex - 1]];
      final pos = (shelfPositionById[shelf.id] ?? 0) + 1;
      shelfPositionById[shelf.id] = pos;

      final isbn = _generateIsbn13(bookGlobalIndex);
      final catalogEntry =
          _algerianCatalog[(bookGlobalIndex - 1) % _algerianCatalog.length];
      final copyNumber = ((bookGlobalIndex - 1) ~/ _algerianCatalog.length) + 1;
      final category = _categories[(bookGlobalIndex - 1) % _categories.length];
      final title = catalogEntry.title;
      final author = catalogEntry.author;
      final isMisplaced = random.nextDouble() < misplacedRate;
      int expected = pos;
      if (isMisplaced && shelf.targetCount > 1) {
        final shift = random.nextInt(7) + 1;
        final direction = random.nextBool() ? 1 : -1;
        expected = (pos + (shift * direction)).clamp(1, shelf.targetCount);
        if (expected == pos) {
          expected = pos == shelf.targetCount ? pos - 1 : pos + 1;
        }
      }

      final now = DateTime.now().subtract(
        Duration(minutes: random.nextInt(50000)),
      );
      books.add({
        'isbn': isbn,
        'title': title,
        'author': author,
        'category': category,
        'coverUrl': null,
        'description':
            'Livre algerien reel (seed). Edition de test copie $copyNumber.',
        'scannedAt': now.toIso8601String(),
        'orderIndex': bookGlobalIndex,
      });
      locations.add({
        'bookIsbn': isbn,
        'libraryId': libraryId,
        'floorId': shelf.floorId,
        'shelfId': shelf.id,
        'position': pos,
        'expectedPosition': expected,
        'isCorrectOrder': expected == pos ? 1 : 0,
        'isFlagged': expected == pos ? 0 : 1,
        'reason': expected == pos ? null : 'Position incorrecte detectee',
        'lastCheckedAt': DateTime.now().toIso8601String(),
        'misplacementCount': expected == pos ? 0 : random.nextInt(4) + 1,
      });
    }

    final labels = <Map<String, Object?>>[];
    for (int i = 0; i < min(books.length, 300); i++) {
      final row = books[i];
      labels.add({
        'id': 'label_seed_${i + 1}',
        'isbn': row['isbn'],
        'title': row['title'],
        'labelText': '${row['title']} - ${row['isbn']}',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    final scans = <Map<String, Object?>>[];
    final corrections = <Map<String, Object?>>[];
    final scanCount = min(80, shelfRefs.length * 2);

    for (int i = 0; i < scanCount; i++) {
      final shelf = shelfRefs[i % shelfRefs.length];
      final shelfBooks = locations
          .where((l) => l['shelfId'] == shelf.id)
          .take(8)
          .toList();
      scans.add({
        'id': 'scan_seed_${i + 1}',
        'libraryId': libraryId,
        'shelfId': shelf.id,
        'floorId': shelf.floorId,
        'scannedBooksJson': jsonEncode(
          shelfBooks
              .map(
                (b) => {
                  'isbn': b['bookIsbn'],
                  'position': b['position'],
                  'expectedPosition': b['expectedPosition'],
                },
              )
              .toList(),
        ),
        'userId': 'seed_user',
        'createdAt': DateTime.now()
            .subtract(Duration(hours: random.nextInt(480)))
            .toIso8601String(),
      });

      final movements = shelfBooks
          .where((b) => b['isCorrectOrder'] == 0)
          .take(4)
          .map(
            (b) => {
              'isbn': b['bookIsbn'],
              'from': b['position'],
              'to': b['expectedPosition'],
            },
          )
          .toList();

      corrections.add({
        'id': 'correction_seed_${i + 1}',
        'libraryId': libraryId,
        'shelfId': shelf.id,
        'movementsJson': jsonEncode(movements),
        'status': movements.isEmpty
            ? 'completed'
            : (i % 2 == 0 ? 'in_progress' : 'completed'),
        'userId': 'seed_user',
        'createdAt': DateTime.now()
            .subtract(Duration(hours: random.nextInt(720)))
            .toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    final distinctShelves = locations.map((e) => e['shelfId']).toSet().length;
    final distinctCategories = books
        .map((e) => e['category'].toString())
        .toSet()
        .length;
    if (distinctShelves <= 1) {
      throw StateError(
        'Seed validation failed: all books mapped to one shelf only.',
      );
    }
    debugPrint(
      'Seed validation OK: shelves=$distinctShelves, categories=$distinctCategories',
    );

    await db.transaction((txn) async {
      for (final table in _tablesToReset) {
        await txn.delete(table);
      }

      await txn.insert('libraries', {
        'id': libraryId,
        'name': libraryName,
        'address': '1 Rue Test, Alger',
        'postalCode': '16000',
        'city': 'Alger',
        'phone': '+213 21 00 00 00',
        'email': 'test@library.local',
        'floorCount': floorCount,
        'latitude': 36.7538,
        'longitude': 3.0588,
        'logoUrl': null,
        'hours': 'Dim-Jeu: 8h-17h, Ven-Sam: 8h-16h',
        'description': 'Bibliotheque de test avec donnees locales completes',
      });

      await txn.insert('librarian_profile', {
        'id': 1,
        'fullName': 'Test Librarian',
        'email': 'librarian@test.local',
        'libraryName': libraryName,
        'phone': '+213 555 000 000',
      });

      for (final row in floors) {
        await txn.insert('floors', row);
      }
      for (final row in shelves) {
        await txn.insert('shelves', row);
      }
      for (final row in books) {
        await txn.insert('books', row);
      }
      for (final row in locations) {
        await txn.insert('book_locations', row);
      }
      for (final row in labels) {
        await txn.insert('isbn_labels', row);
      }
      for (final row in scans) {
        await txn.insert('scans', row);
      }
      for (final row in corrections) {
        await txn.insert('corrections', row);
      }
    });

    return DevDatabaseSeedSummary(
      libraries: 1,
      floors: floors.length,
      shelves: shelves.length,
      books: books.length,
      locations: locations.length,
      scans: scans.length,
      corrections: corrections.length,
      labels: labels.length,
    );
  }

  static const List<String> _tablesToReset = [
    'corrections',
    'scans',
    'isbn_labels',
    'book_locations',
    'books',
    'shelves',
    'floors',
    'libraries',
    'librarian_profile',
  ];

  static const List<String> _categories = [
    'أدب',
    'خيال علمي',
    'فلسفة',
    'تاريخ',
    'علوم',
    'تقنية',
    'لغات',
    'اقتصاد',
    'فن',
    'سيرة',
  ];

  static const List<_CatalogBook> _algerianCatalog = [
    _CatalogBook('Nedjma', 'Kateb Yacine', 'أدب'),
    _CatalogBook('Le Polygone etoile', 'Kateb Yacine', 'أدب'),
    _CatalogBook('Le Cercle des represailles', 'Kateb Yacine', 'أدب'),
    _CatalogBook('La Soif', 'Assia Djebar', 'أدب'),
    _CatalogBook('Les Impatients', 'Assia Djebar', 'أدب'),
    _CatalogBook('Les Enfants du Nouveau Monde', 'Assia Djebar', 'أدب'),
    _CatalogBook('Les Alouettes naives', 'Assia Djebar', 'أدب'),
    _CatalogBook(
      'Femmes d\'Alger dans leur appartement',
      'Assia Djebar',
      'أدب',
    ),
    _CatalogBook('L\'Amour, la fantasia', 'Assia Djebar', 'أدب'),
    _CatalogBook('Ombre sultane', 'Assia Djebar', 'أدب'),
    _CatalogBook('Loin de Medine', 'Assia Djebar', 'أدب'),
    _CatalogBook('Vaste est la prison', 'Assia Djebar', 'أدب'),
    _CatalogBook('Le blanc de l\'Algerie', 'Assia Djebar', 'أدب'),
    _CatalogBook('Oran, langue morte', 'Assia Djebar', 'أدب'),
    _CatalogBook('Les Nuits de Strasbourg', 'Assia Djebar', 'أدب'),
    _CatalogBook('La femme sans sepulture', 'Assia Djebar', 'أدب'),
    _CatalogBook(
      'La disparition de la langue francaise',
      'Assia Djebar',
      'أدب',
    ),
    _CatalogBook(
      'Nulle part dans la maison de mon pere',
      'Assia Djebar',
      'سيرة',
    ),
    _CatalogBook('Memory in the Flesh', 'Ahlam Mosteghanemi', 'أدب'),
    _CatalogBook('Chaos of the Senses', 'Ahlam Mosteghanemi', 'أدب'),
    _CatalogBook('Bed Hopper', 'Ahlam Mosteghanemi', 'أدب'),
    _CatalogBook('Black Suits You', 'Ahlam Mosteghanemi', 'أدب'),
    _CatalogBook('La grande maison', 'Mohammed Dib', 'أدب'),
    _CatalogBook('L\'incendie', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Au cafe', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Le metier a tisser', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Baba Fekrane', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Un ete africain', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Ombre gardienne', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Qui se souvient de la mer', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Cours sur la rive sauvage', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Le talisman', 'Mohammed Dib', 'أدب'),
    _CatalogBook('La danse du roi', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Dieu en barbarie', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Le Maitre de chasse', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Habel', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Mille hourras pour une gueuse', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Les terrasses d\'Orsol', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Le sommeil d\'Eve', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Neiges de Marbre', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Le Desert sans detour', 'Mohammed Dib', 'أدب'),
    _CatalogBook('L\'infante Maure', 'Mohammed Dib', 'أدب'),
    _CatalogBook('L\'arbre a dires', 'Mohammed Dib', 'أدب'),
    _CatalogBook('L\'Enfant-Jazz', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Le Cœur insulaire', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Comme un bruit d\'abeilles', 'Mohammed Dib', 'أدب'),
    _CatalogBook('L.A. Trip', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Simorgh', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Laezza', 'Mohammed Dib', 'أدب'),
    _CatalogBook('Le Fils du pauvre', 'Mouloud Feraoun', 'أدب'),
    _CatalogBook('La terre et le sang', 'Mouloud Feraoun', 'أدب'),
    _CatalogBook('Jours de Kabylie', 'Mouloud Feraoun', 'أدب'),
    _CatalogBook('Les Chemins qui montent', 'Mouloud Feraoun', 'أدب'),
    _CatalogBook('Les Isefra de Si Mhand Oumhand', 'Mouloud Feraoun', 'أدب'),
    _CatalogBook('Journal 1955-1962', 'Mouloud Feraoun', 'سيرة'),
    _CatalogBook(
      'Le printemps n\'en sera que plus beau',
      'Rachid Mimouni',
      'أدب',
    ),
    _CatalogBook('Le Fleuve detourne', 'Rachid Mimouni', 'أدب'),
    _CatalogBook('Une peine a vivre', 'Rachid Mimouni', 'أدب'),
    _CatalogBook('Tombeza', 'Rachid Mimouni', 'أدب'),
    _CatalogBook('L\'Honneur de la tribu', 'Rachid Mimouni', 'أدب'),
    _CatalogBook('La ceinture de l\'ogresse', 'Rachid Mimouni', 'أدب'),
    _CatalogBook('La Malediction', 'Rachid Mimouni', 'أدب'),
    _CatalogBook('Chroniques de Tanger', 'Rachid Mimouni', 'أدب'),
    _CatalogBook('Morituri', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('Les Hirondelles de Kaboul', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('L\'Attentat', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('Les Sirenes de Bagdad', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('Ce que le jour doit a la nuit', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('L\'Equation africaine', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('Les anges meurent de nos blessures', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('La derniere nuit du rais', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('Khalil', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('Qu\'attendent les singes', 'Yasmina Khadra', 'أدب'),
    _CatalogBook('Les Vigiles', 'Tahar Djaout', 'أدب'),
    _CatalogBook('L\'invention du Desert', 'Tahar Djaout', 'أدب'),
    _CatalogBook('Les Chercheurs d\'os', 'Tahar Djaout', 'أدب'),
    _CatalogBook('L\'exproprie', 'Tahar Djaout', 'أدب'),
    _CatalogBook('Le dernier ete de la raison', 'Tahar Djaout', 'أدب'),
    _CatalogBook('La Derniere impression', 'Malek Haddad', 'أدب'),
    _CatalogBook('Je t\'offrirai une gazelle', 'Malek Haddad', 'أدب'),
    _CatalogBook('L\'Eleve et la lecon', 'Malek Haddad', 'أدب'),
    _CatalogBook('Le Quai aux Fleurs ne repond plus', 'Malek Haddad', 'أدب'),
    _CatalogBook('Meursault, contre-enquete', 'Kamel Daoud', 'أدب'),
    _CatalogBook('Zabor ou Les psaumes', 'Kamel Daoud', 'أدب'),
    _CatalogBook('La Repudiation', 'Rachid Boudjedra', 'أدب'),
    _CatalogBook('Les Figuiers de Barbarie', 'Rachid Boudjedra', 'أدب'),
    _CatalogBook('Les Funerailles', 'Rachid Boudjedra', 'أدب'),
    _CatalogBook('The Blue Gate', 'Waciny Laredj', 'أدب'),
    _CatalogBook('The Andalucian House', 'Waciny Laredj', 'أدب'),
    _CatalogBook('Ashes of the East', 'Waciny Laredj', 'أدب'),
    _CatalogBook('The kingdom of the butterfly', 'Waciny Laredj', 'أدب'),
    _CatalogBook('The Prince\'s Book', 'Waciny Laredj', 'تاريخ'),
    _CatalogBook('La Soumission', 'Amin Zaoui', 'أدب'),
    _CatalogBook('Haras de Femmes', 'Amin Zaoui', 'أدب'),
    _CatalogBook('Festin de Mensonges', 'Amin Zaoui', 'أدب'),
    _CatalogBook('La Chambre de la Vierge Impure', 'Amin Zaoui', 'أدب'),
    _CatalogBook('Le miel de la sieste', 'Amin Zaoui', 'أدب'),
    _CatalogBook('L\'enfant de l\'oeuf', 'Amin Zaoui', 'أدب'),
  ];

  String _generateIsbn13(int index) {
    final first12 = '978${index.toString().padLeft(9, '0')}';
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(first12[i]);
      sum += i.isEven ? digit : digit * 3;
    }
    final checkDigit = (10 - (sum % 10)) % 10;
    return '$first12$checkDigit';
  }
}

class _CatalogBook {
  const _CatalogBook(this.title, this.author, this.category);

  final String title;
  final String author;
  final String category;
}

Future<void> maybeSeedFullDatabaseOnStartup() async {
  const enableSeed = bool.fromEnvironment('SEED_FULL_DATABASE');
  if (!kDebugMode || !enableSeed) return;

  const booksFromEnv = int.fromEnvironment('SEED_BOOKS', defaultValue: 1200);
  const floorsFromEnv = int.fromEnvironment('SEED_FLOORS', defaultValue: 4);
  const shelvesFromEnv = int.fromEnvironment(
    'SEED_SHELVES_PER_FLOOR',
    defaultValue: 12,
  );

  final summary = await DevDatabaseSeedService().seedFullDatabase(
    bookCount: booksFromEnv,
    floorCount: floorsFromEnv,
    shelvesPerFloor: shelvesFromEnv,
  );

  debugPrint('✅ Full local database seeded: $summary');
}
