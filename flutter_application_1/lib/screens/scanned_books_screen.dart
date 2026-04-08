import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/library.dart';
import '../models/shelf.dart';
import '../services/firebase_service.dart';
import 'ar_book_detection_screen.dart';

class ScannedBooksScreen extends StatefulWidget {
  final Library library;

  const ScannedBooksScreen({super.key, required this.library});

  @override
  State<ScannedBooksScreen> createState() => _ScannedBooksScreenState();
}

class _ScannedBooksScreenState extends State<ScannedBooksScreen> {
  final FirebaseService _firebase = FirebaseService();
  List<Book> _books = [];
  bool _loading = true;
  bool _openingScanner = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await _firebase.getScannedBooks();
    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح السجل'),
        content: const Text('هل تريد مسح سجل المسح كاملاً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _firebase.clearScanHistory();
    await _loadBooks();
  }

  Future<void> _openScanner() async {
    if (_openingScanner) return;
    setState(() => _openingScanner = true);
    try {
      final shelves = await _getAllShelves();
      if (!mounted) return;
      if (shelves.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد رفوف. أضف رفاً أولاً')),
        );
        return;
      }

      final shelf = shelves.length == 1
          ? shelves.first
          : await _pickShelf(shelves);
      if (!mounted || shelf == null) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ARBookDetectionScreen(
            shelfId: shelf.id,
            libraryId: widget.library.id,
          ),
        ),
      );
      // Refresh list when coming back
      await _loadBooks();
    } finally {
      if (mounted) setState(() => _openingScanner = false);
    }
  }

  Future<List<Shelf>> _getAllShelves() async {
    final floors =
        await _firebase.getFloorsByLibrary(widget.library.id);
    final shelves = <Shelf>[];
    for (final floor in floors) {
      shelves.addAll(
          await _firebase.getShelvesByFloor(widget.library.id, floor.id));
    }
    return shelves;
  }

  Future<Shelf?> _pickShelf(List<Shelf> shelves) {
    return showModalBottomSheet<Shelf>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: shelves.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = shelves[i];
            return ListTile(
              leading: const Icon(Icons.shelves),
              title: Text(s.name),
              subtitle: Text(s.category ?? ''),
              onTap: () => Navigator.pop(context, s),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _books.isEmpty ? _buildEmpty() : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openingScanner ? null : _openScanner,
        backgroundColor: const Color(0xFF38ada9),
        icon: _openingScanner
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('مسح رف',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لم يتم مسح أي كتاب بعد',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على "مسح رف" لبدء المسح',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 80), // space for FAB
        ],
      ),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الكتب المسوحة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_books.length} كتاب',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.white70),
                  tooltip: 'مسح السجل',
                  onPressed: _clearHistory,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildBookCard(_books[index]),
              childCount: _books.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF38ada9).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book, color: Color(0xFF38ada9), size: 22),
        ),
        title: Text(book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${book.author} • ${book.isbn}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            await _firebase.deleteBook(book.isbn);
            await _loadBooks();
          },
        ),
      ),
    );
  }
}
