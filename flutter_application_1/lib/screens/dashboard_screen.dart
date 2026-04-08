import 'package:flutter/material.dart';
import '../models/library.dart';
import '../models/shelf.dart';
import '../services/app_settings_service.dart';
import '../services/firebase_service.dart';
import '../services/local_librarian_profile_service.dart';
import 'add_books_rows_screen.dart';
import 'book_search_screen.dart';
import 'ar_book_detection_screen.dart';
import 'scanned_books_screen.dart';
import 'library_info_screen.dart';
import 'faq_screen.dart';

/// Écran du tableau de bord principal - Hub central avec tous les features
class DashboardScreen extends StatefulWidget {
  final Library library;
  final LibrarianProfile? librarianProfile;

  const DashboardScreen({
    super.key,
    required this.library,
    this.librarianProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _faqTutorialSeenKey = 'faq_tutorial_seen_v1';

  final FirebaseService _firebase = FirebaseService();
  final AppSettingsService _settings = AppSettingsService();
  int _currentIndex = 0;
  int _totalBooks = 0;
  int _totalShelves = 0;
  int _misplacedBooks = 0;
  int _correctBooks = 0;
  bool _openingArScanner = false;

  String get _displayLibraryName {
    final fromProfile = widget.librarianProfile?.libraryName.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return widget.library.name;
  }

  String get _displaySubtitle {
    final fromProfile = widget.librarianProfile?.fullName.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return widget.library.city;
  }

  String? get _displayDescription {
    final profile = widget.librarianProfile;
    if (profile == null) return widget.library.description;

    final email = profile.email.trim();
    final phone = profile.phone?.trim();
    if (email.isEmpty && (phone == null || phone.isEmpty)) {
      return widget.library.description;
    }

    if (phone != null && phone.isNotEmpty) {
      return 'البريد: $email | الهاتف: $phone';
    }
    return 'البريد: $email';
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFaqTutorialIfFirstTime();
    });
  }

  Future<void> _showFaqTutorialIfFirstTime() async {
    final seen = await _settings.getBool(_faqTutorialSeenKey);
    if (seen || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مرحباً 👋'),
        content: const Text(
          'يمكنك العثور على شرح التطبيق في صفحة FAQ.\n'
          'من الأعلى يمين الشاشة اضغط أيقونة علامة الاستفهام (؟).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                this.context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
            },
            child: const Text('فتح FAQ'),
          ),
        ],
      ),
    );
    await _settings.setBool(_faqTutorialSeenKey, true);
  }

  Future<void> _loadStats() async {
    final books = await _firebase.searchBooks('', libraryId: widget.library.id);
    final floors = await _firebase.getFloorsByLibrary(widget.library.id);
    final locations = await _firebase.getBookLocationsByLibrary(
      widget.library.id,
    );
    int shelvesCount = 0;
    for (final floor in floors) {
      final shelves = await _firebase.getShelvesByFloor(
        widget.library.id,
        floor.id,
      );
      shelvesCount += shelves.length;
    }
    final misplaced = locations.where((l) => !l.isCorrectOrder).length;
    final correct = locations.where((l) => l.isCorrectOrder).length;
    if (!mounted) return;
    setState(() {
      _totalBooks = books.length;
      _totalShelves = shelvesCount;
      _misplacedBooks = misplaced;
      _correctBooks = correct;
    });
  }

  List<Widget> _buildScreens() => [
    _buildHomeTab(),
    BookSearchScreen(library: widget.library),
    ScannedBooksScreen(library: widget.library),
    AddBooksRowsScreen(library: widget.library),
    LibraryInfoScreen(library: widget.library),
  ];

  Future<void> _openArScanner() async {
    if (_openingArScanner) return;
    setState(() => _openingArScanner = true);
    try {
      final floors = await _firebase.getFloorsByLibrary(widget.library.id);
      if (!mounted) return;
      if (floors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد طوابق. أضف طابقاً أولاً')),
        );
        return;
      }

      final shelves = <Shelf>[];
      for (final floor in floors) {
        final floorShelves = await _firebase.getShelvesByFloor(
          widget.library.id,
          floor.id,
        );
        shelves.addAll(floorShelves);
      }
      if (!mounted) return;
      if (shelves.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد رفوف. أضف رفاً أولاً')),
        );
        return;
      }

      final selectedShelf = await _pickShelfForAr(shelves);
      if (!mounted || selectedShelf == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARBookDetectionScreen(
            shelfId: selectedShelf.id,
            libraryId: widget.library.id,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingArScanner = false);
      }
    }
  }

  Future<Shelf?> _pickShelfForAr(List<Shelf> shelves) async {
    if (shelves.length == 1) return shelves.first;
    return showModalBottomSheet<Shelf>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: shelves.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final shelf = shelves[index];
            return ListTile(
              leading: const Icon(Icons.shelves),
              title: Text(shelf.name),
              subtitle: Text('السعة: ${shelf.capacity}'),
              onTap: () => Navigator.pop(context, shelf),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: const Icon(
                Icons.local_library_outlined,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayLibraryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displaySubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2f9d98),
                const Color(0xFF38ada9),
                const Color(0xFF3c6382).withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqScreen()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.help_outline, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LibraryInfoScreen(library: widget.library),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.info_outline, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _buildScreens()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF38ada9),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'بحث'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2),
            label: 'الممسوحة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'إضافة',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'معلومات'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final totalTracked = _correctBooks + _misplacedBooks;
    final accuracy = totalTracked == 0
        ? 0
        : ((_correctBooks / totalTracked) * 100).round();

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        children: [
          // Hero Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF38ada9),
                  const Color(0xFF38ada9).withValues(alpha: 0.8),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.library_books, color: Colors.white, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'مرحباً بك في',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayLibraryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_displayDescription != null)
                  Text(
                    _displayDescription!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجراءات سريعة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Grid(
                  children: [
                    _buildActionCard(
                      icon: Icons.search,
                      title: 'البحث عن كتاب',
                      subtitle: 'العثور على كتاب معين',
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                    _buildActionCard(
                      icon: Icons.view_in_ar,
                      title: 'تصحيح الواقع المعزز',
                      subtitle: 'إعادة ترتيب الكتب',
                      onTap: _openArScanner,
                    ),
                    _buildActionCard(
                      icon: Icons.list,
                      title: 'مسوحاتي',
                      subtitle: 'عرض السجل',
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                    _buildActionCard(
                      icon: Icons.add_box_outlined,
                      title: 'إضافة كتب ورفوف',
                      subtitle: 'إدخال محلي سريع',
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إحصائيات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shelves,
                        value: '$_totalShelves',
                        label: 'رفوف',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.menu_book,
                        value: '$_totalBooks',
                        label: 'كتب',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.analytics_outlined,
                        value: '$accuracy%',
                        label: 'دقّة الترتيب',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نصيحة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _misplacedBooks > 0
                              ? 'يوجد $_misplacedBooks كتاب يحتاج ترتيب. استخدم واقع معزز للتصحيح.'
                              : 'جميع الكتب الممسوحة حالياً في أماكنها الصحيحة.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GridItem(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF38ada9).withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF38ada9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF38ada9), size: 22),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF38ada9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF38ada9), size: 24),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for 2-column grid layout
class Grid extends StatelessWidget {
  final List<Widget> children;

  const Grid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1, // Slightly taller to prevent overflow
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Wrapper for grid item
class GridItem extends StatelessWidget {
  final Widget child;

  const GridItem({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
