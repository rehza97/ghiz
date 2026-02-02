import 'package:flutter/material.dart';
import '../models/library.dart';
import '../models/book.dart';
import '../models/book_location.dart';
import '../services/firebase_service.dart';

/// Écran de recherche de livres - données depuis Firebase
class BookSearchScreen extends StatefulWidget {
  final Library library;

  const BookSearchScreen({
    super.key,
    required this.library,
  });

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebase = FirebaseService();
  List<Book> _searchResults = [];
  String _selectedCategory = 'الكل';
  bool _loading = false;
  String? _error;

  final List<String> _categories = [
    'الكل',
    'رواية',
    'أدب جزائري',
    'خيال علمي',
    'فانتازيا',
    'ديستوبيا',
    'رومانسية كلاسيكية',
    'مغامرة كلاسيكية',
    'كلاسيكي فرنسي',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialBooks();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch();
  }

  Future<void> _loadInitialBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await _firebase.searchBooks('');
      if (mounted) {
        setState(() {
          _searchResults = _filterByCategoryList(books, _selectedCategory);
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

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await _firebase.searchBooks(query.isEmpty ? '' : query);
      if (mounted) {
        setState(() {
          _searchResults = _filterByCategoryList(books, _selectedCategory);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Loading / Error
          if (_loading && _searchResults.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF38ada9))),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
            )
          else ...[
            // Results Count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child:                     Text(
                      _searchResults.isEmpty
                      ? 'لا توجد كتب'
                      : _searchResults.length == 1 ? 'كتاب واحد' : '${_searchResults.length} كتب',
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = _searchResults[index];
                      return FutureBuilder<BookLocation?>(
                        future: _firebase.getBookLocation(book.isbn, widget.library.id),
                        builder: (context, snapshot) {
                          return _buildBookCard(book, snapshot.data);
                        },
                      );
                    },
                    childCount: _searchResults.length,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                          children: [
                            Chip(
                              label: Text(
                                book.category,
                                style: const TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                              backgroundColor:
                                  Colors.blue[100],
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
                    future: _firebase.getFloorById(widget.library.id, location.floorId).then((f) => f?.name ?? '-'),
                    builder: (context, snap) => _buildDetailRow('الطابق', snap.data ?? '...'),
                  ),
                  _buildDetailRow(
                    'الرف',
                    '${location.shelfId}',
                  ),
                  _buildDetailRow(
                    'الموقع',
                    '${location.position}',
                  ),
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('التوجيه إلى الكتاب...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('تحديد الموقع'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38ada9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
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
