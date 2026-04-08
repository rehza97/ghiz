import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/book.dart';
import '../models/book_location.dart';
import '../models/floor.dart';
import '../models/library.dart';
import '../models/shelf.dart';
import '../services/firebase_service.dart';

class AddBooksRowsScreen extends StatefulWidget {
  const AddBooksRowsScreen({super.key, required this.library});

  final Library library;

  @override
  State<AddBooksRowsScreen> createState() => _AddBooksRowsScreenState();
}

class _AddBooksRowsScreenState extends State<AddBooksRowsScreen> {
  final FirebaseService _service = FirebaseService();
  final _bookFormKey = GlobalKey<FormState>();
  final _rowFormKey = GlobalKey<FormState>();

  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();

  final _rowNameController = TextEditingController();
  final _rowCategoryController = TextEditingController();
  final _rowCapacityController = TextEditingController(text: '50');

  bool _savingBook = false;
  bool _savingRow = false;
  bool _autoGenerateIsbn = true;
  bool _keepValuesForNext = true;
  int _autoFillSeed = 0;

  List<Floor> _floors = [];
  List<Shelf> _shelves = [];
  String? _selectedFloorId;
  String? _selectedShelfId;
  late String _activeLibraryId;

  final List<Map<String, String>> _quickBookTemplates = const [
    {
      'title': 'L\'Étranger',
      'author': 'Albert Camus',
      'category': 'أدب جزائري',
    },
    {'title': 'Dune', 'author': 'Frank Herbert', 'category': 'خيال علمي'},
    {
      'title': 'Le Seigneur des Anneaux',
      'author': 'J.R.R. Tolkien',
      'category': 'فانتازيا',
    },
    {'title': '1984', 'author': 'George Orwell', 'category': 'ديستوبيا'},
  ];

  @override
  void initState() {
    super.initState();
    _activeLibraryId = widget.library.id;
    _loadFloorsAndShelves();
  }

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _rowNameController.dispose();
    _rowCategoryController.dispose();
    _rowCapacityController.dispose();
    super.dispose();
  }

  Floor? _floorById(String? id) {
    if (id == null) return null;
    for (final floor in _floors) {
      if (floor.id == id) return floor;
    }
    return null;
  }

  Shelf? _shelfById(String? id) {
    if (id == null) return null;
    for (final shelf in _shelves) {
      if (shelf.id == id) return shelf;
    }
    return null;
  }

  Future<void> _loadFloorsAndShelves() async {
    final resolvedLibraryId = await _resolveLibraryForShelfData();
    final floors = await _service.getFloorsByLibrary(resolvedLibraryId);
    final shelves = <Shelf>[];
    for (final floor in floors) {
      final floorShelves = await _service.getShelvesByFloor(
        resolvedLibraryId,
        floor.id,
      );
      shelves.addAll(floorShelves);
    }

    if (!mounted) return;
    setState(() {
      _activeLibraryId = resolvedLibraryId;
      _floors = floors;
      _shelves = shelves;
      _selectedFloorId = floors.isNotEmpty ? floors.first.id : null;
      _selectedShelfId = shelves.isNotEmpty ? shelves.first.id : null;
    });
  }

  Future<String> _resolveLibraryForShelfData() async {
    final currentFloors = await _service.getFloorsByLibrary(_activeLibraryId);
    if (currentFloors.isNotEmpty) return _activeLibraryId;
    final libraries = await _service.getLibraries();
    for (final library in libraries) {
      final floors = await _service.getFloorsByLibrary(library.id);
      if (floors.isNotEmpty) return library.id;
    }
    return _activeLibraryId;
  }

  /// Generates a valid EAN-13 ISBN that is not already in the database.
  /// Retries with a small random offset until a free code is found.
  Future<String> _generateIsbn13() async {
    int attempt = 0;
    while (true) {
      final time = (DateTime.now().microsecondsSinceEpoch + attempt).toString();
      final first12 = '978${time.substring(time.length - 9)}';
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        final digit = int.parse(first12[i]);
        sum += (i % 2 == 0) ? digit : digit * 3;
      }
      final checksum = (10 - (sum % 10)) % 10;
      final isbn = '$first12$checksum';
      if (!await _service.isbnExists(isbn)) return isbn;
      attempt++;
    }
  }

  Future<void> _addBook({bool continueFast = false}) async {
    if (_savingBook) return;
    final valid = _bookFormKey.currentState?.validate() ?? false;
    if (!valid) return;

    final isbn = _isbnController.text.trim().isEmpty
        ? (_autoGenerateIsbn ? await _generateIsbn13() : '')
        : _isbnController.text.trim();
    if (isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال ISBN أو تفعيل التوليد التلقائي'),
        ),
      );
      return;
    }

    setState(() => _savingBook = true);
    try {
      final book = Book(
        isbn: isbn,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        category: _categoryController.text.trim(),
      );
      await _service.saveBook(book);

      Shelf? selectedShelf;
      try {
        selectedShelf = _shelves.firstWhere((s) => s.id == _selectedShelfId);
      } catch (_) {
        selectedShelf = null;
      }
      if (selectedShelf != null) {
        final current = await _service.getShelfBooks(
          _activeLibraryId,
          selectedShelf.id,
        );
        final nextPosition = current.length + 1;
        await _service.updateBookPosition(
          BookLocation(
            bookIsbn: isbn,
            libraryId: _activeLibraryId,
            floorId: selectedShelf.floorId,
            shelfId: selectedShelf.id,
            position: nextPosition,
            expectedPosition: nextPosition,
            isCorrectOrder: true,
          ),
        );
      }

      if (!mounted) return;

      if (_keepValuesForNext || continueFast) {
        _isbnController.text = _autoGenerateIsbn ? await _generateIsbn13() : '';
        _titleController.clear();
      } else {
        _isbnController.clear();
        _titleController.clear();
        _authorController.clear();
        _categoryController.clear();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت إضافة الكتاب بنجاح')));
    } finally {
      if (mounted) {
        setState(() => _savingBook = false);
      }
    }
  }

  Future<void> _addRow() async {
    if (_savingRow) return;
    final valid = _rowFormKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_selectedFloorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد طابق متاح لإضافة الرف')),
      );
      return;
    }

    setState(() => _savingRow = true);
    try {
      final shelfId = 'shelf_${DateTime.now().millisecondsSinceEpoch}';
      final capacity = int.tryParse(_rowCapacityController.text.trim()) ?? 50;
      final shelf = Shelf(
        id: shelfId,
        name: _rowNameController.text.trim(),
        floorId: _selectedFloorId!,
        libraryId: _activeLibraryId,
        x: 0,
        y: 0,
        z: 0,
        width: 2,
        height: 2.5,
        depth: 0.3,
        category: _rowCategoryController.text.trim(),
        capacity: capacity,
        currentCount: 0,
      );
      await _service.saveShelf(shelf);
      await _loadFloorsAndShelves();
      if (!mounted) return;
      setState(() {
        _selectedShelfId = shelf.id;
      });
      _rowNameController.clear();
      _rowCategoryController.clear();
      _rowCapacityController.text = '50';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الرف وتعيينه كاختيار سريع')),
      );
      await _showShelfBarcodeDialog(shelf);
    } finally {
      if (mounted) {
        setState(() => _savingRow = false);
      }
    }
  }

  Future<void> _addFloorQuick() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final floorNumberController = TextEditingController(
      text: _floors.isEmpty
          ? '0'
          : (_floors.map((f) => f.floorNumber).reduce((a, b) => a > b ? a : b) +
                    1)
                .toString(),
    );
    int localSeed = 0;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة طابق'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الطابق',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: floorNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم الطابق',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (kDebugMode)
            TextButton.icon(
              onPressed: () {
                localSeed++;
                nameController.text =
                    'طابق تجريبي ${DateTime.now().second}_$localSeed';
                floorNumberController.text = (100 + localSeed).toString();
                descriptionController.text = 'وصف تلقائي $localSeed';
              },
              icon: const Icon(Icons.science_outlined),
              label: const Text('Auto Fill'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (created != true) return;
    final floorName = nameController.text.trim();
    final floorNumber = int.tryParse(floorNumberController.text.trim());
    if (floorName.isEmpty || floorNumber == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم ورقم طابق صحيحين')),
      );
      return;
    }

    final floor = Floor(
      id: 'floor_${DateTime.now().millisecondsSinceEpoch}',
      name: floorName,
      floorNumber: floorNumber,
      libraryId: _activeLibraryId,
      mapAssetPath: null,
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      shelfCount: 0,
      mapWidth: null,
      mapHeight: null,
    );
    await _service.saveFloor(floor);
    await _loadFloorsAndShelves();
    if (!mounted) return;
    setState(() {
      _selectedFloorId = floor.id;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة الطابق')));
  }

  Future<void> _applyQuickTemplate(Map<String, String> template) async {
    _titleController.text = template['title'] ?? '';
    _authorController.text = template['author'] ?? '';
    _categoryController.text = template['category'] ?? '';
    if (_autoGenerateIsbn || _isbnController.text.trim().isEmpty) {
      _isbnController.text = await _generateIsbn13();
    }
  }

  Future<void> _autoFillBookForm() async {
    _autoFillSeed++;
    if (_autoGenerateIsbn) {
      _isbnController.text = await _generateIsbn13();
    } else {
      _isbnController.text =
          '978000000${(_autoFillSeed % 1000).toString().padLeft(3, '0')}';
    }
    _titleController.text = 'كتاب تجريبي $_autoFillSeed';
    _authorController.text = 'مؤلف تجريبي $_autoFillSeed';
    _categoryController.text = 'تصنيف ${(_autoFillSeed % 5) + 1}';
  }

  void _autoFillRowForm() {
    _autoFillSeed++;
    _rowNameController.text = 'R-${DateTime.now().second}-$_autoFillSeed';
    _rowCategoryController.text = 'Cat-${(_autoFillSeed % 5) + 1}';
    _rowCapacityController.text = (30 + (_autoFillSeed % 40)).toString();
  }

  /// The barcode value stored on a shelf label — prefixed so the scanner
  /// can distinguish shelf barcodes from book ISBNs.
  static String shelfBarcodeValue(Shelf shelf) => 'SHELF:${shelf.id}';

  Future<bool> _ensureGalleryPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      var status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      status = await Permission.photosAddOnly.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      var status = await Permission.photos.status;
      if (!status.isGranted) status = await Permission.photos.request();
      if (status.isGranted) return true;
      var storage = await Permission.storage.status;
      if (!storage.isGranted) storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return false;
  }

  Future<void> _showShelfBarcodeDialog(Shelf shelf) async {
    final imageKey = GlobalKey();
    final barcodeValue = shelfBarcodeValue(shelf);

    final action = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'باركود الرف: ${shelf.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اطبع هذا الملصق وألصقه على الرف حتى يتعرف عليه الماسح تلقائياً.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Center(
                  child: RepaintBoundary(
                    key: imageKey,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: barcodeValue,
                            width: 260,
                            height: 80,
                            drawText: false,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shelf.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (shelf.category != null &&
                              shelf.category!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              shelf.category!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            'سعة: ${shelf.capacity}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'close'),
                      child: const Text('إغلاق'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'save'),
                      icon: const Icon(Icons.save_alt, size: 18),
                      label: const Text('حفظ كصورة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (action != 'save' || !mounted) return;

    final granted = await _ensureGalleryPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد إذن للوصول إلى الصور')),
        );
      }
      return;
    }

    try {
      final boundary =
          imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final fileName =
          'shelf_${shelf.id}_${DateTime.now().millisecondsSinceEpoch}';
      await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: fileName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ باركود الرف "${shelf.name}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFloor = _floorById(_selectedFloorId);
    final selectedShelf = _shelfById(_selectedShelfId);

    return DefaultTabController(
      length: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF38ada9).withValues(alpha: 0.08),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: _sectionCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'وحدة الإدخال السريع',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(
                          Icons.apartment_rounded,
                          selectedFloor?.name ?? 'بدون طابق',
                        ),
                        _pill(
                          Icons.view_stream_outlined,
                          selectedShelf?.name ?? 'بدون رف',
                        ),
                        _pill(
                          Icons.library_books_outlined,
                          '${_shelves.length} رف',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white,
                  child: const TabBar(
                    labelColor: Color(0xFF38ada9),
                    indicatorColor: Color(0xFF38ada9),
                    tabs: [
                      Tab(icon: Icon(Icons.menu_book), text: 'إضافة كتاب'),
                      Tab(icon: Icon(Icons.shelves), text: 'إضافة رف'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [_buildAddBookTab(), _buildAddRowTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBookTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: Form(
        key: _bookFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              child: Wrap(
                runSpacing: 8,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('ISBN تلقائي'),
                    selected: _autoGenerateIsbn,
                    onSelected: (value) {
                      setState(() => _autoGenerateIsbn = value);
                      if (value && _isbnController.text.trim().isEmpty) {
                        _generateIsbn13().then((isbn) {
                          if (mounted) _isbnController.text = isbn;
                        });
                      }
                    },
                  ),
                  FilterChip(
                    label: const Text('وضع سريع'),
                    selected: _keepValuesForNext,
                    onSelected: (value) =>
                        setState(() => _keepValuesForNext = value),
                  ),
                  if (_autoGenerateIsbn)
                    TextButton.icon(
                      onPressed: () async =>
                          _isbnController.text = await _generateIsbn13(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('تجديد ISBN'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'قوالب سريعة',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickBookTemplates.map((template) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(template['title'] ?? ''),
                            onPressed: () async =>
                                _applyQuickTemplate(template),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (kDebugMode) ...[
              OutlinedButton.icon(
                onPressed: () async => _autoFillBookForm(),
                icon: const Icon(Icons.science_outlined),
                label: const Text('Auto Fill Book'),
              ),
              const SizedBox(height: 10),
            ],
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات الكتاب',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _isbnController,
                    decoration: InputDecoration(
                      labelText: 'ISBN / Barcode',
                      border: const OutlineInputBorder(),
                      suffixIcon: _autoGenerateIsbn
                          ? IconButton(
                              onPressed: () async {
                                _isbnController.text = await _generateIsbn13();
                              },
                              icon: const Icon(Icons.auto_awesome),
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (_autoGenerateIsbn) return null;
                      return (value == null || value.trim().isEmpty)
                          ? 'مطلوب'
                          : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الكتاب',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'المؤلف',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'مطلوب'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختيار رف سريع',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_shelves.isEmpty)
                    Text(
                      'لا توجد رفوف بعد. أضف رفاً من تبويب "إضافة رف".',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _shelves.take(16).map((shelf) {
                        final selected = shelf.id == _selectedShelfId;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: Text('${shelf.name} (${shelf.floorId})'),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedShelfId = shelf.id),
                            ),
                            IconButton(
                              tooltip: 'باركود الرف',
                              icon: const Icon(Icons.qr_code, size: 18),
                              onPressed: () => _showShelfBarcodeDialog(shelf),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _savingBook
                        ? null
                        : () => _addBook(continueFast: false),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _savingBook
                        ? null
                        : () => _addBook(continueFast: true),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('إضافة سريع'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: Form(
        key: _rowFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختيار الطابق',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedFloorId,
                    decoration: const InputDecoration(
                      labelText: 'الطابق',
                      border: OutlineInputBorder(),
                    ),
                    items: _floors
                        .map(
                          (floor) => DropdownMenuItem<String>(
                            value: floor.id,
                            child: Text(floor.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFloorId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addFloorQuick,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة طابق'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (kDebugMode) ...[
              OutlinedButton.icon(
                onPressed: _autoFillRowForm,
                icon: const Icon(Icons.science_outlined),
                label: const Text('Auto Fill Row'),
              ),
              const SizedBox(height: 10),
            ],
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات الرف',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _rowNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الرف / الصف',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rowCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'تصنيف الرف',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'مطلوب'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rowCapacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'سعة الرف',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'مطلوب';
                      final capacity = int.tryParse(value.trim());
                      if (capacity == null || capacity <= 0) {
                        return 'رقم غير صالح';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _savingRow ? null : _addRow,
                icon: const Icon(Icons.add),
                label: const Text('إضافة الرف'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF38ada9).withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF38ada9).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1f7f7b)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1f7f7b),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
