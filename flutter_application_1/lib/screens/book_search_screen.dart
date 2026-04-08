import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/library.dart';
import '../models/book.dart';
import '../models/book_location.dart';
import '../models/floor.dart';
import '../models/shelf.dart';
import '../services/firebase_service.dart';

/// Écran de recherche de livres - données depuis Firebase
class BookSearchScreen extends StatefulWidget {
  final Library library;

  const BookSearchScreen({super.key, required this.library});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  static const String _allFilter = '__all__';
  static const int _pageSize = 40;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebase = FirebaseService();
  StreamSubscription<void>? _booksChangesSub;
  List<Book> _searchResults = [];
  List<Book> _visibleResults = [];
  String _selectedCategory = 'الكل';
  String _selectedFloorId = _allFilter;
  String _selectedShelfId = _allFilter;
  String _selectedStatus = _allFilter;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _autoFillSeed = 0;

  List<String> _categories = ['الكل'];
  List<Floor> _floors = [];
  List<Shelf> _shelves = [];
  Map<String, BookLocation> _locationsByIsbn = {};
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
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _booksChangesSub = FirebaseService.booksChanges.listen((_) {
      _performSearch();
    });
    _loadInitialBooks();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _booksChangesSub?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadMoreResults();
    }
  }

  void _resetVisibleResults() {
    final initialCount = _searchResults.length < _pageSize
        ? _searchResults.length
        : _pageSize;
    _visibleResults = _searchResults.take(initialCount).toList();
  }

  void _loadMoreResults() {
    if (_loadingMore) return;
    if (_visibleResults.length >= _searchResults.length) return;
    setState(() => _loadingMore = true);
    final start = _visibleResults.length;
    final end = (start + _pageSize).clamp(0, _searchResults.length);
    final nextChunk = _searchResults.sublist(start, end);
    setState(() {
      _visibleResults = [..._visibleResults, ...nextChunk];
      _loadingMore = false;
    });
  }

  Future<void> _loadInitialBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await _firebase.searchBooks(
        '',
        libraryId: widget.library.id,
      );
      final floors = await _firebase.getFloorsByLibrary(widget.library.id);
      final shelves = await _firebase.getShelvesByLibrary(widget.library.id);
      final locations = await _firebase.getBookLocationsByLibrary(
        widget.library.id,
      );
      if (mounted) {
        final categories = {
          'الكل',
          ...books
              .map((book) => book.category)
              .where((c) => c.trim().isNotEmpty),
        }.toList();
        final locationsByIsbn = <String, BookLocation>{
          for (final location in locations) location.bookIsbn: location,
        };
        setState(() {
          _categories = categories;
          _floors = floors;
          _shelves = shelves;
          _locationsByIsbn = locationsByIsbn;
          if (!_categories.contains(_selectedCategory)) {
            _selectedCategory = 'الكل';
          }
          _ensureFilterIntegrity();
          _searchResults = _applyAllFilters(books);
          _resetVisibleResults();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<Book> _filterByCategoryList(List<Book> books, String category) {
    if (category == 'الكل') return books;
    return books.where((b) => b.category == category).toList();
  }

  List<Shelf> get _availableShelvesForSelectedFloor {
    if (_selectedFloorId == _allFilter) return _shelves;
    return _shelves.where((s) => s.floorId == _selectedFloorId).toList();
  }

  void _ensureFilterIntegrity() {
    final floorIds = _floors.map((f) => f.id).toSet();
    if (_selectedFloorId != _allFilter &&
        !floorIds.contains(_selectedFloorId)) {
      _selectedFloorId = _allFilter;
    }

    final shelfIds = _availableShelvesForSelectedFloor.map((s) => s.id).toSet();
    if (_selectedShelfId != _allFilter &&
        !shelfIds.contains(_selectedShelfId)) {
      _selectedShelfId = _allFilter;
    }
  }

  List<Book> _applyAllFilters(List<Book> books) {
    var filtered = _filterByCategoryList(books, _selectedCategory);

    if (_selectedFloorId != _allFilter) {
      filtered = filtered.where((book) {
        final location = _locationsByIsbn[book.isbn];
        return location != null && location.floorId == _selectedFloorId;
      }).toList();
    }

    if (_selectedShelfId != _allFilter) {
      filtered = filtered.where((book) {
        final location = _locationsByIsbn[book.isbn];
        return location != null && location.shelfId == _selectedShelfId;
      }).toList();
    }

    if (_selectedStatus != _allFilter) {
      filtered = filtered.where((book) {
        final location = _locationsByIsbn[book.isbn];
        if (_selectedStatus == 'correct') {
          return location != null && location.isCorrectOrder;
        }
        if (_selectedStatus == 'needs_fix') {
          return location != null && !location.isCorrectOrder;
        }
        if (_selectedStatus == 'unassigned') {
          return location == null;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'correct':
        return 'في مكانه';
      case 'needs_fix':
        return 'يحتاج ترتيب';
      case 'unassigned':
        return 'بدون موقع';
      default:
        return 'الكل';
    }
  }

  String _shelfNameFor(String shelfId) {
    for (final shelf in _shelves) {
      if (shelf.id == shelfId) return shelf.name;
    }
    return shelfId;
  }

  String _floorNameFor(String floorId) {
    for (final floor in _floors) {
      if (floor.id == floorId) return floor.name;
    }
    return floorId;
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await _firebase.searchBooks(
        query.isEmpty ? '' : query,
        libraryId: widget.library.id,
      );
      if (mounted) {
        final categories = {
          'الكل',
          ...books
              .map((book) => book.category)
              .where((c) => c.trim().isNotEmpty),
        }.toList();
        setState(() {
          _categories = categories;
          if (!_categories.contains(_selectedCategory)) {
            _selectedCategory = 'الكل';
          }
          _ensureFilterIntegrity();
          _searchResults = _applyAllFilters(books);
          _resetVisibleResults();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _performSearch();
  }

  void _onFloorChanged(String? floorId) {
    setState(() {
      _selectedFloorId = floorId ?? _allFilter;
      final shelfIds = _availableShelvesForSelectedFloor
          .map((s) => s.id)
          .toSet();
      if (_selectedShelfId != _allFilter &&
          !shelfIds.contains(_selectedShelfId)) {
        _selectedShelfId = _allFilter;
      }
    });
    _performSearch();
  }

  void _onShelfChanged(String? shelfId) {
    setState(() {
      _selectedShelfId = shelfId ?? _allFilter;
    });
    _performSearch();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Search Bar
          SliverAppBar(
            floating: true,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            flexibleSpace: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'العنوان، المؤلف أو الرقم الدولي...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF38ada9),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _showAddBookDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة كتاب'),
                ),
              ),
            ),
          ),

          // Category Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _filterByCategory(category),
                        selectedColor: const Color(0xFF38ada9),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey<String>('floor_$_selectedFloorId'),
                          initialValue: _selectedFloorId,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'الطابق',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: _allFilter,
                              child: Text('كل الطوابق'),
                            ),
                            ..._floors.map(
                              (floor) => DropdownMenuItem(
                                value: floor.id,
                                child: Text(floor.name),
                              ),
                            ),
                          ],
                          onChanged: _onFloorChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey<String>('shelf_$_selectedShelfId'),
                          initialValue: _selectedShelfId,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'الرف',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: _allFilter,
                              child: Text('كل الرفوف'),
                            ),
                            ..._availableShelvesForSelectedFloor.map(
                              (shelf) => DropdownMenuItem(
                                value: shelf.id,
                                child: Text(shelf.name),
                              ),
                            ),
                          ],
                          onChanged: _onShelfChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final status in const [
                          _allFilter,
                          'correct',
                          'needs_fix',
                          'unassigned',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_statusLabel(status)),
                              selected: _selectedStatus == status,
                              onSelected: (_) => _onStatusChanged(status),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedFloorId = _allFilter;
                              _selectedShelfId = _allFilter;
                              _selectedStatus = _allFilter;
                              _selectedCategory = 'الكل';
                            });
                            _performSearch();
                          },
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('مسح الفلاتر'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading / Error
          if (_loading && _visibleResults.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF38ada9)),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loadInitialBooks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Results Count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  _searchResults.isEmpty
                      ? 'لا توجد كتب'
                      : _searchResults.length == 1
                      ? 'كتاب واحد'
                      : '${_searchResults.length} كتب',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Books List
            if (_searchResults.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد كتب',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جرّب بحثاً آخر',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final book = _visibleResults[index];
                    return _buildBookCard(book, _locationsByIsbn[book.isbn]);
                  }, childCount: _visibleResults.length),
                ),
              ),
            if (_visibleResults.length < _searchResults.length)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: _loadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : TextButton(
                            onPressed: _loadMoreResults,
                            child: const Text('تحميل المزيد'),
                          ),
                  ),
                ),
              ),
          ],

          // Bottom spacing
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book, BookLocation? location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookDetails(book, location),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book icon/placeholder
                  Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38ada9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF38ada9).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.library_books,
                      color: Color(0xFF38ada9),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Book info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تأليف ${book.author}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text(
                                book.category,
                                style: const TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.blue[100],
                            ),
                            if (location != null)
                              Chip(
                                label: Text(
                                  location.isCorrectOrder
                                      ? 'في مكانه'
                                      : 'يحتاج ترتيب',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: location.isCorrectOrder
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                              ),
                            if (location != null)
                              Chip(
                                label: Text(
                                  _floorNameFor(location.floorId),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.purple[50],
                              ),
                            if (location != null)
                              Chip(
                                label: Text(
                                  _shelfNameFor(location.shelfId),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: Colors.teal[50],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action button
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        color: const Color(0xFF38ada9),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showBookDetails(book, location),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookDetails(Book book, dynamic location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38ada9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.library_books,
                        color: Color(0xFF38ada9),
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(book.category),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Details
                Text(
                  'معلومات',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('الرقم الدولي', book.isbn),
                _buildDetailRow('التصنيف', book.category),
                if (location != null) ...[
                  FutureBuilder<String>(
                    future: _firebase
                        .getFloorById(location.libraryId, location.floorId)
                        .then((f) => f?.name ?? '-'),
                    builder: (context, snap) =>
                        _buildDetailRow('الطابق', snap.data ?? '...'),
                  ),
                  _buildDetailRow('الرف', _shelfNameFor(location.shelfId)),
                  _buildDetailRow('الموقع', '${location.position}'),
                  _buildDetailRow(
                    'الحالة',
                    location.isCorrectOrder ? '✓ في مكانه' : '⚠ يحتاج ترتيب',
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditBookDialog(book);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('تعديل'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _printOrSaveIsbnLabel(book);
                        },
                        icon: const Icon(Icons.local_printshop_outlined),
                        label: const Text('طباعة/حفظ الملصق'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38ada9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteBook(book);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'حذف الكتاب',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddBookDialog() async {
    final newBook = await _showBookFormDialog();
    if (newBook == null) return;
    await _firebase.saveBook(newBook);
    await _performSearch();
  }

  Future<void> _printOrSaveIsbnLabel(Book book) async {
    // Look up shelf info before opening dialog
    final location = await _firebase.getBookLocation(
      book.isbn,
      widget.library.id,
    );
    String? shelfName;
    if (location != null) {
      final shelf = await _firebase.getShelfByLibraryAndShelfId(
        location.libraryId,
        location.shelfId,
      );
      shelfName = shelf?.name;
    }

    final labelText =
        'ISBN: ${book.isbn}\nTITLE: ${book.title}\nAUTHOR: ${book.author}'
        '${shelfName != null ? '\nSHELF: $shelfName' : ''}';
    final imageKey = GlobalKey();
    final action = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF38ada9).withValues(alpha: 0.14),
                        const Color(0xFF3c6382).withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ملصق ISBN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RepaintBoundary(
                          key: imageKey,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Composite barcode: "{isbn} {shelfName}" when
                                // shelf is known, plain ISBN otherwise.
                                // Always Code128 for composite (EAN-13 is digits-only).
                                BarcodeWidget(
                                  barcode: shelfName != null
                                      ? Barcode.code128()
                                      : _barcodeTypeFor(book.isbn),
                                  data: shelfName != null
                                      ? '${book.isbn} $shelfName'
                                      : book.isbn,
                                  width: 260,
                                  height: 90,
                                  drawText: false,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  shelfName != null
                                      ? '${book.isbn}  $shelfName'
                                      : book.isbn,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  book.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (shelfName != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38ada9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'رف: $shelfName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(labelText),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'save_image'),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('حفظ صورة'),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, 'print'),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('طباعة'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (action == 'save_image') {
      final boundary =
          imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر إنشاء صورة الملصق')));
        return;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حفظ الصورة')));
        return;
      }
      final hasPermission = await _ensureGalleryPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يلزم منح صلاحية الصور لحفظ ملصق الباركود'),
          ),
        );
        return;
      }
      final Uint8List bytes = byteData.buffer.asUint8List();
      final fileName =
          'isbn_${book.isbn}_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: fileName,
      );
      if (!mounted) return;
      final isSuccess =
          (result['isSuccess'] == true) ||
          (result['filePath'] != null) ||
          (result['savedFilePath'] != null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess ? 'تم حفظ الصورة في المعرض' : 'تعذر حفظ الصورة في المعرض',
          ),
        ),
      );
      return;
    }

    if (action == 'print') {
      await _printIsbnLabel(
        isbn: book.isbn,
        title: book.title,
        author: book.author,
        shelfName: shelfName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال الملصق للطباعة')));
    }
  }

  Future<void> _printIsbnLabel({
    required String isbn,
    required String title,
    required String author,
    String? shelfName,
  }) async {
    final data = shelfName != null ? '$isbn $shelfName' : isbn;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ISBN Label',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  barcode: shelfName != null
                      ? pw.Barcode.code128()
                      : pw.Barcode.ean13(),
                  data: shelfName != null ? data : isbn,
                  width: 180,
                  height: 56,
                ),
                pw.SizedBox(height: 8),
                pw.Text(data, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 6),
                pw.Text(
                  title,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(author, style: const pw.TextStyle(fontSize: 10)),
                if (shelfName != null) ...[
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'SHELF: $shelfName',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<bool> _ensureGalleryPermission() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      var status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      // Fallback for devices/flows where add-only is surfaced separately.
      status = await Permission.photosAddOnly.request();
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      var photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        photosStatus = await Permission.photos.request();
      }
      if (photosStatus.isGranted) return true;

      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      if (storageStatus.isGranted) return true;

      if (photosStatus.isPermanentlyDenied ||
          storageStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }

    return true;
  }

  Future<void> _showEditBookDialog(Book book) async {
    final newBook = await _showBookFormDialog(initial: book);
    if (newBook == null) return;
    if (newBook.isbn != book.isbn) {
      await _firebase.deleteBook(book.isbn);
    }
    await _firebase.saveBook(newBook);
    await _performSearch();
  }

  Future<Book?> _showBookFormDialog({Book? initial}) async {
    final isbnController = TextEditingController();
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final categoryController = TextEditingController();
    bool autoGenerateIsbn = initial == null;
    int localSeed = 0;

    if (initial != null) {
      isbnController.text = initial.isbn;
      titleController.text = initial.title;
      authorController.text = initial.author;
      categoryController.text = initial.category;
    } else {
      isbnController.text = await _generateIsbn13();
    }

    return showDialog<Book?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(initial == null ? 'إضافة كتاب' : 'تعديل الكتاب'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('ISBN تلقائي'),
                        selected: autoGenerateIsbn,
                        onSelected: (value) async {
                          setStateDialog(() => autoGenerateIsbn = value);
                          if (value && isbnController.text.trim().isEmpty) {
                            isbnController.text = await _generateIsbn13();
                          }
                        },
                      ),
                      if (autoGenerateIsbn)
                        TextButton.icon(
                          onPressed: () async =>
                              isbnController.text = await _generateIsbn13(),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('تجديد'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'قوالب سريعة',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickBookTemplates.map((template) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(template['title'] ?? ''),
                            onPressed: () async {
                              titleController.text = template['title'] ?? '';
                              authorController.text = template['author'] ?? '';
                              categoryController.text =
                                  template['category'] ?? '';
                              if (autoGenerateIsbn ||
                                  isbnController.text.trim().isEmpty) {
                                isbnController.text = await _generateIsbn13();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _input(
                    isbnController,
                    'الرقم الدولي',
                    suffix: autoGenerateIsbn
                        ? IconButton(
                            onPressed: () async =>
                                isbnController.text = await _generateIsbn13(),
                            icon: const Icon(Icons.auto_awesome),
                          )
                        : null,
                  ),
                  _input(titleController, 'العنوان'),
                  _input(authorController, 'المؤلف'),
                  _input(categoryController, 'التصنيف'),
                ],
              ),
            ),
          ),
          actions: [
            if (kDebugMode)
              TextButton.icon(
                onPressed: () async {
                  localSeed++;
                  _autoFillSeed++;
                  isbnController.text = autoGenerateIsbn
                      ? await _generateIsbn13()
                      : '978111111${(_autoFillSeed % 1000).toString().padLeft(3, '0')}';
                  titleController.text = 'كتاب بحث $_autoFillSeed';
                  authorController.text = 'مؤلف $_autoFillSeed';
                  categoryController.text = 'تصنيف ${(localSeed % 6) + 1}';
                },
                icon: const Icon(Icons.science_outlined),
                label: const Text('Auto Fill'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final isbn =
                    isbnController.text.trim().isEmpty && autoGenerateIsbn
                    ? await _generateIsbn13()
                    : isbnController.text.trim();
                final title = titleController.text.trim();
                final author = authorController.text.trim();
                final category = categoryController.text.trim();
                if (isbn.isEmpty ||
                    title.isEmpty ||
                    author.isEmpty ||
                    category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء كل الحقول')),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  Book(
                    isbn: isbn,
                    title: title,
                    author: author,
                    category: category,
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكتاب'),
        content: Text('هل تريد حذف "${book.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _firebase.deleteBook(book.isbn);
    await _performSearch();
  }

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
      if (!await _firebase.isbnExists(isbn)) return isbn;
      attempt++;
    }
  }

  bool _isValidEan13(String value) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(value[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    return (10 - (sum % 10)) % 10 == int.parse(value[12]);
  }

  Barcode _barcodeTypeFor(String value) {
    final isNumeric = RegExp(r'^\d+$').hasMatch(value);
    if (isNumeric && value.length == 13 && _isValidEan13(value)) {
      return Barcode.ean13();
    }
    if (isNumeric && value.length == 12) return Barcode.upcA();
    return Barcode.code128();
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: suffix,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
