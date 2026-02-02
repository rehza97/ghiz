import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/book_ar_data.dart';
import '../models/shelf_book.dart';
import '../models/book_correction_guide.dart';
import '../models/book_location.dart';
import '../models/book.dart';
import '../models/shelf.dart';
import '../services/ar_service.dart';
import '../services/firebase_service.dart';
import 'book_correction_screen.dart';

/// Helper class to track barcode with screen position
class _BarcodeWithPosition {
  final String isbn;
  final double screenX;
  final String rawValue;
  final int detectionIndex;
  
  _BarcodeWithPosition({
    required this.isbn,
    required this.screenX,
    required this.rawValue,
    required this.detectionIndex,
  });
}

/// Helper class to track detected book information
class _DetectedBookInfo {
  int detectionOrder; // Physical position from left (1, 2, 3...)
  double screenX;
  DateTime detectedAt;
  
  _DetectedBookInfo({
    required this.detectionOrder,
    required this.screenX,
    required this.detectedAt,
  });
  
  void updatePosition(int newOrder, double newScreenX) {
    detectionOrder = newOrder;
    screenX = newScreenX;
  }
}

/// Écran de détection AR des livres
class ARBookDetectionScreen extends StatefulWidget {
  final String shelfId;
  final String libraryId;

  const ARBookDetectionScreen({
    super.key,
    required this.shelfId,
    required this.libraryId,
  });

  @override
  State<ARBookDetectionScreen> createState() => _ARBookDetectionScreenState();
}

class _ARBookDetectionScreenState extends State<ARBookDetectionScreen> {
  late MobileScannerController _scannerController;
  final ARService _arService = ARService();
  final FirebaseService _firebase = FirebaseService();

  // Shelf loaded once (no floorId on widget)
  Shelf? _shelf;
  /// Expected books on shelf (for AR overlay and correction guide)
  List<ShelfBook> _expectedShelfBooks = [];
  final Map<String, Book> _detectedBookByIsbn = {};
  final Map<String, BookLocation> _detectedLocationByIsbn = {};

  // Track last scan time to prevent too rapid processing (debounce)
  DateTime? _lastScanTime;
  final List<String> _detectedBarcodes = [];
  // Track detected books with their physical detection order (left-to-right from scanning)
  final Map<String, _DetectedBookInfo> _detectedBooksInfo = {};
  // Track the order of first detection (physical left-to-right order)
  int _nextDetectionOrder = 1;
  List<BookARData> _arDataList = [];
  BookCorrectionGuide? _correctionGuide;

  final bool _isScanning = true;
  final double _distanceToShelf = 2.0; // Distance simulée
  String _scanStatus = 'وجّه الكاميرا نحو الرف';
  bool _isFocusing = false;
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.all],
      torchEnabled: false,
      autoStart: true,
    );
    _loadShelf();
  }

  Future<void> _loadShelf() async {
    try {
      final shelf = await _firebase.getShelfByLibraryAndShelfId(widget.libraryId, widget.shelfId);
      if (mounted) {
        setState(() {
          _shelf = shelf;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AR] Failed to load shelf: $e');
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodes) async {
    if (!_isScanning) return;

    // Debounce: prevent processing too rapidly (max once every 200ms)
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 200) {
      return;
    }

    // Track barcodes with their display values for left-to-right ordering
    // Use displayValue position info if available, otherwise use detection sequence
    final List<_BarcodeWithPosition> barcodesWithPos = [];
    
    // Log all detected barcodes
    if (kDebugMode && barcodes.barcodes.isNotEmpty) {
      debugPrint('📷 [BARCODE SCAN] Detected ${barcodes.barcodes.length} barcode(s) in frame');
    }
    
    for (int idx = 0; idx < barcodes.barcodes.length; idx++) {
      final barcode = barcodes.barcodes[idx];
      final value = barcode.rawValue;
      if (value != null) {
        // Normalize ISBN format (handle with/without dashes)
        final normalizedIsbn = _normalizeIsbn(value);
        
        // Estimate screen X position from detection index and display value
        // mobile_scanner detects barcodes roughly left-to-right when scanning
        // Use index as a proxy for left-to-right order when multiple detected
        double screenX = idx / math.max(barcodes.barcodes.length - 1, 1.0); // Normalize to 0-1
        
        // If displayValue exists, try to extract position hints
        if (barcode.displayValue != null && barcode.displayValue!.isNotEmpty) {
          // Use detection order - first detected is typically leftmost
          screenX = idx / math.max(barcodes.barcodes.length, 1.0);
        }
        
        barcodesWithPos.add(_BarcodeWithPosition(
          isbn: normalizedIsbn,
          screenX: screenX,
          rawValue: value,
          detectionIndex: idx,
        ));
      }
    }

    // Sort by screen X position (left to right) to determine physical order in this frame
    barcodesWithPos.sort((a, b) => a.screenX.compareTo(b.screenX));
    
    if (barcodesWithPos.isEmpty) return;

    _lastScanTime = DateTime.now();

    // ---------------------------------------------------------
    // DYNAMIC REORDERING LOGIC
    // ---------------------------------------------------------
    // 1. Collect all available "order slots" from detected books + allocate new ones
    List<int> availableOrders = [];
    List<_BarcodeWithPosition> newBooks = [];
    
    for (var b in barcodesWithPos) {
      if (_detectedBooksInfo.containsKey(b.isbn)) {
        availableOrders.add(_detectedBooksInfo[b.isbn]!.detectionOrder);
      } else {
        newBooks.add(b);
      }
    }

    // Allocate new orders for new books (using next available global IDs)
    for (var _ in newBooks) {
      availableOrders.add(_nextDetectionOrder++);
    }

    // Sort available orders to distribute them left-to-right across the screen
    availableOrders.sort();

    // 2. Assign sorted orders to the screen-sorted barcodes
    // This ensures that books on the left get the lower order numbers
    bool arNeedsUpdate = false;

    for (int i = 0; i < barcodesWithPos.length; i++) {
      final barcodeInfo = barcodesWithPos[i];
      final newOrder = availableOrders[i];
      
      if (_detectedBooksInfo.containsKey(barcodeInfo.isbn)) {
        // EXISTING BOOK: Update position if changed
        final info = _detectedBooksInfo[barcodeInfo.isbn]!;
        if (info.detectionOrder != newOrder) {
           if (kDebugMode) {
             debugPrint('🔄 [REORDER] ${barcodeInfo.isbn} moved: ${info.detectionOrder} -> $newOrder');
           }
           info.detectionOrder = newOrder;
           info.screenX = barcodeInfo.screenX;
           arNeedsUpdate = true;
        }
      } else {
        // NEW BOOK: Add it
        if (kDebugMode) {
          debugPrint('✅ [BARCODE SCAN] New barcode detected: ${barcodeInfo.isbn} -> Order: $newOrder');
        }
        _addDetectedBook(barcodeInfo.isbn, newOrder, barcodeInfo.screenX);
        // _addDetectedBook triggers setState, so we don't need to set arNeedsUpdate here
        // but we continue the loop to handle others
      }
    }

    if (arNeedsUpdate) {
      await _updateARView();
      if (mounted) setState(() {});
    }
  }

  String _normalizeIsbn(String isbn) {
    // Trim whitespace first (leading/trailing spaces from scanner)
    final trimmed = isbn.trim();
    
    // Remove all dashes and spaces
    final cleaned = trimmed.replaceAll(RegExp(r'[-\s]'), '');
    
    if (kDebugMode) {
      debugPrint('🔧 [NORMALIZE] Input: "$isbn" → Trimmed: "$trimmed" → Cleaned: "$cleaned" (${cleaned.length} chars)');
    }
    
    // If it's a 13-digit ISBN, format as 978-XXXXXXXXXX (check digit in second group)
    if (cleaned.length == 13 && RegExp(r'^\d{13}$').hasMatch(cleaned)) {
      final formatted = '${cleaned.substring(0, 3)}-${cleaned.substring(3)}';
      if (kDebugMode) {
        debugPrint('✅ [NORMALIZE] Formatted: "$formatted"');
      }
      return formatted;
    }
    
    // If it's a valid 10 or 13 digit number but not standard format, return cleaned
    if (RegExp(r'^\d{10}$|^\d{13}$').hasMatch(cleaned)) {
      if (kDebugMode) {
        debugPrint('⚠️  [NORMALIZE] Valid ISBN but non-standard format, returning cleaned: "$cleaned"');
      }
      return cleaned;
    }
    
    // Return trimmed version if it doesn't match ISBN format
    if (kDebugMode) {
      debugPrint('❌ [NORMALIZE] Invalid ISBN format, returning trimmed: "$trimmed"');
    }
    return trimmed;
  }

  Future<void> _addDetectedBook(String barcode, int physicalDetectionOrder, double screenX) async {
    if (_detectedBarcodes.contains(barcode)) {
      if (kDebugMode) {
        debugPrint('⚠️  [BOOK ADD] Duplicate barcode ignored: $barcode');
      }
      return;
    }

    final book = await _firebase.getBookByIsbn(barcode);
    if (book == null) {
      if (kDebugMode) {
        debugPrint('❌ [BOOK ADD] Book not found for ISBN: $barcode');
      }
      _showSnackBar('الباركود غير معروف: $barcode', Colors.red);
      return;
    }

    if (kDebugMode) {
      debugPrint('📚 [BOOK ADD] Found book: ${book.title} by ${book.author}');
      debugPrint('   ISBN: $barcode, Category: ${book.category}');
    }

    final location = await _firebase.getBookLocation(barcode, widget.libraryId);
    if (location == null || location.shelfId != widget.shelfId) {
      if (kDebugMode) {
        debugPrint('❌ [BOOK ADD] Wrong shelf - Expected: ${widget.shelfId}, Found: ${location?.shelfId ?? "null"}');
      }
      _showSnackBar('${book.title} ليس على هذا الرف', Colors.red);
      return;
    }

    _detectedBookByIsbn[barcode] = book;
    _detectedLocationByIsbn[barcode] = location;
    _detectedBooksInfo[barcode] = _DetectedBookInfo(
      detectionOrder: physicalDetectionOrder,
      screenX: screenX,
      detectedAt: DateTime.now(),
    );

    if (kDebugMode) {
      debugPrint('✅ [BOOK ADD] Book added successfully:');
      debugPrint('   Title: ${book.title}');
      debugPrint('   Physical Position (Left-to-Right): $physicalDetectionOrder');
      debugPrint('   Database Position: ${location.position}');
      debugPrint('   Expected Position: ${location.expectedPosition}');
      debugPrint('   Correct Order: ${location.isCorrectOrder}');
      debugPrint('   Total detected: ${_detectedBarcodes.length + 1}');
    }

    setState(() {
      _detectedBarcodes.add(barcode);
    });
    await _updateARView();
    if (mounted) setState(() {});

    _showSnackBar('تم اكتشاف ${book.title} ✓ (الموقع: $physicalDetectionOrder)', Colors.green);
  }

  Future<void> _updateARView() async {
    final shelf = _shelf;
    if (shelf == null) return;

    // Sort detected barcodes by physical detection order (left-to-right)
    final sortedBarcodes = List<String>.from(_detectedBarcodes);
    sortedBarcodes.sort((a, b) {
      final infoA = _detectedBooksInfo[a];
      final infoB = _detectedBooksInfo[b];
      if (infoA == null && infoB == null) return 0;
      if (infoA == null) return 1;
      if (infoB == null) return -1;
      return infoA.detectionOrder.compareTo(infoB.detectionOrder);
    });

    final detectedBooks = sortedBarcodes
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final barcode = entry.value;
          final book = _detectedBookByIsbn[barcode];
          final location = _detectedLocationByIsbn[barcode];
          final detectionInfo = _detectedBooksInfo[barcode];
          
          if (book == null || location == null) return null;

          final physicalPosition = detectionInfo?.detectionOrder ?? (index + 1);
          final expectedPosition = location.expectedPosition;
          final isCorrect = physicalPosition == expectedPosition;
          final deviation = (expectedPosition - physicalPosition).abs();

          if (kDebugMode) {
            debugPrint('📋 [AR UPDATE] ${book.title}:');
            debugPrint('   Physical Position (scanned left-to-right): $physicalPosition');
            debugPrint('   Expected Position (database): $expectedPosition');
            debugPrint('   Is Correct: $isCorrect');
          }

          return ShelfBook(
            book: book,
            currentPosition: physicalPosition,
            expectedPosition: expectedPosition,
            barcode: barcode,
            isCorrect: isCorrect,
            deviation: deviation,
            movementDirection:
                physicalPosition < expectedPosition ? 'يمين' : 'يسار',
          );
        })
        .whereType<ShelfBook>()
        .toList();

    _arDataList = _arService.generateShelfARView(
      detectedBooks: detectedBooks,
      getBook: (isbn) => _detectedBookByIsbn[isbn]!,
      getLocation: (isbn) => _detectedLocationByIsbn[isbn]!,
      shelf: shelf,
      distanceToShelf: _distanceToShelf,
    );

    final locations = await _firebase.getShelfBooks(widget.libraryId, widget.shelfId);
    final expectedShelfBooks = <ShelfBook>[];
    for (final loc in locations) {
      final book = await _firebase.getBookByIsbn(loc.bookIsbn);
      if (book != null) {
        expectedShelfBooks.add(ShelfBook(
          book: book,
          currentPosition: loc.position,
          expectedPosition: loc.expectedPosition,
          barcode: loc.bookIsbn,
          isCorrect: loc.isCorrectOrder,
          deviation: (loc.expectedPosition - loc.position).abs(),
          movementDirection: loc.position < loc.expectedPosition ? 'يمين' : 'يسار',
        ));
      }
    }
    _expectedShelfBooks = expectedShelfBooks;
    _correctionGuide = _arService.calculateCorrectionGuide(
      detectedBooks: detectedBooks,
      expectedBooks: _expectedShelfBooks,
      shelfId: widget.shelfId,
    );

    _updateScanStatus();
  }

  void _updateScanStatus() {
    if (_detectedBarcodes.isEmpty) {
      _scanStatus = 'وجّه الكاميرا نحو الرف (يدعم عدة رموز)';
    } else {
      final count = _detectedBarcodes.length;
      if (_correctionGuide?.isInCorrectOrder ?? false) {
        _scanStatus = '$count كتاب مكتشف - الكل بالترتيب الصحيح ✓';
      } else {
        final errors = _correctionGuide?.totalErrorsFound ?? 0;
        _scanStatus = '$count كتاب مكتشف - $errors يحتاج تصحيح';
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearDetection() {
    setState(() {
      _detectedBarcodes.clear();
      _detectedBooksInfo.clear();
      _detectedBookByIsbn.clear();
      _detectedLocationByIsbn.clear();
      _nextDetectionOrder = 1;
      _arDataList.clear();
      _expectedShelfBooks = [];
      _correctionGuide = null;
      _lastScanTime = null;
      _updateScanStatus();
    });
  }

  void _handleTapToFocus(TapDownDetails details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = details.localPosition;

    setState(() {
      _focusPoint = localPosition;
      _isFocusing = true;
    });

    // Trigger auto-focus by restarting the scanner
    _scannerController.stop();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scannerController.start();
        // Hide focus indicator after focus animation
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _isFocusing = false;
              _focusPoint = null;
            });
          }
        });
      }
    });

    _showSnackBar('تم ضبط البؤرة', Colors.cyan);
  }

  void _triggerAutoFocus() {
    setState(() {
      _isFocusing = true;
    });

    // Restart scanner to trigger auto-focus
    _scannerController.stop();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scannerController.start();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _isFocusing = false;
            });
          }
        });
      }
    });

    _showSnackBar('تم تفعيل الضبط التلقائي', Colors.cyan);
  }

  void _toggleTorch() {
    final currentTorch = _scannerController.torchEnabled;
    _scannerController.toggleTorch();
    _showSnackBar(
      currentTorch ? 'الفلاش مغلق' : 'الفلاش مفتوح',
      Colors.amber,
    );
  }

  Widget _buildFocusIndicator(Offset position) {
    return Positioned(
      left: position.dx - 40,
      top: position.dy - 40,
      child: AnimatedOpacity(
        opacity: _isFocusing ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.cyan,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.center_focus_strong,
              color: Colors.cyan,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusControls() {
    return Column(
      children: [
        // Auto-focus button
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isFocusing ? Icons.center_focus_strong : Icons.center_focus_weak,
              color: _isFocusing ? Colors.cyan : Colors.white,
            ),
            onPressed: _triggerAutoFocus,
            tooltip: 'ضبط تلقائي',
          ),
        ),
        const SizedBox(height: 8),
        // Torch button
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _scannerController.torchEnabled
                  ? Icons.flash_on
                  : Icons.flash_off,
              color: _scannerController.torchEnabled
                  ? Colors.amber
                  : Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: 'فلاش',
          ),
        ),
      ],
    );
  }

  void _showTestBooksDialog() async {
    try {
      final locations = await _firebase.getShelfBooks(widget.libraryId, widget.shelfId);
      final shelfBooks = <Map<String, dynamic>>[];
      for (final loc in locations) {
        final book = await _firebase.getBookByIsbn(loc.bookIsbn);
        if (book != null) shelfBooks.add({'location': loc, 'book': book});
      }

      if (kDebugMode) {
        debugPrint('📋 [TEST BOOKS] Showing ${shelfBooks.length} test books for shelf ${widget.shelfId}');
      }

      if (!mounted) return;
      _showTestBooksDialogContent(shelfBooks);
    } catch (e) {
      if (mounted) {
        _showSnackBar('خطأ: $e', Colors.red);
      }
    }
  }

  void _showTestBooksDialogContent(List<Map<String, dynamic>> shelfBooks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.book, color: Color(0xFF38ada9)),
            const SizedBox(width: 8),
            const Text('كتب التجربة'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الأرقام الدولية المتوفرة على هذا الرف:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ...shelfBooks.map((item) {
                final location = item['location'] as BookLocation;
                final book = item['book'] as Book;
                final isCorrect = location.isCorrectOrder;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.warning,
                            color: isCorrect ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ISBN: ${location.bookIsbn}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الموقع: ${location.position} → ${location.expectedPosition}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCorrect ? Colors.green : Colors.orange,
                        ),
                      ),
                      if (!isCorrect)
                        Text(
                          '❌ في مكان خاطئ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'نصيحة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• استخدم زر لوحة المفاتيح (🔤) للتجربة دون باركود\n'
                      '• أو امسح الباركود المرئي\n'
                      '• يدعم الأفقي والعمودي وجميع الزوايا',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال الرقم الدولي يدوياً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'للتجربة دون باركود فعلي، أدخل الرقم الدولي:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '978-2070364008',
                labelText: 'الرقم الدولي',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك إدخال عدة أرقام دولية مفصولة بفواصل:\n\n'
              'أمثلة:\n'
              '978-2070364008\n'
              '978-2070113018, 978-2080701473 (متعددة)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // Support multiple ISBNs separated by commas
                final input = controller.text.trim();
                final isbns = input.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                
                // Process all ISBNs in order (left-to-right = first to last in input)
                for (int idx = 0; idx < isbns.length; idx++) {
                  final isbnInput = isbns[idx];
                  // Remove dashes if present
                  final cleaned = isbnInput.replaceAll('-', '').replaceAll(' ', '');
                  // Add dashes in correct format if needed
                  final formattedIsbn = cleaned.length == 13
                      ? '${cleaned.substring(0, 3)}-${cleaned.substring(3, 12)}-${cleaned.substring(12)}'
                      : isbnInput;
                  // For manual input, assign position based on input order (left-to-right)
                  final manualOrder = _nextDetectionOrder++;
                  _addDetectedBook(formattedIsbn, manualOrder, idx / math.max(isbns.length - 1, 1.0));
                }
                
                Navigator.pop(context);
                
                if (isbns.length > 1) {
                  _showSnackBar('تمت إضافة ${isbns.length} رقم دولي', Colors.blue);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38ada9),
            ),
            child: const Text('مسح', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startCorrection() {
    if (_correctionGuide == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookCorrectionScreen(
          correctionGuide: _correctionGuide!,
          shelfId: widget.shelfId,
          libraryId: widget.libraryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اكتشاف الكتب بالواقع المعزز'),
        backgroundColor: const Color(0xFF38ada9),
        elevation: 0,
        actions: [
          // Test books reference
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showTestBooksDialog,
            tooltip: 'كتب التجربة',
          ),
          // Manual input for testing
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: _showManualInputDialog,
            tooltip: 'إدخال الرقم يدوياً (تجربة)',
          ),
          if (_detectedBarcodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearDetection,
              tooltip: 'إعادة تعيين',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Caméra avec scan de codes-barres avec tap-to-focus
          // Supports horizontal, vertical, and all orientations automatically
          GestureDetector(
            onTapDown: (details) => _handleTapToFocus(details),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcode,
              // Fit mode for better focus
              fit: BoxFit.cover,
            ),
          ),

          // Focus indicator overlay
          if (_focusPoint != null)
            _buildFocusIndicator(_focusPoint!),

          // Overlay AR avec informations des livres
          if (_arDataList.isNotEmpty)
            _buildAROverlay(),

          // Panneau inférieur avec informations
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),

          // Statut du scan
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildStatusCard(),
          ),

          // Focus control buttons
          Positioned(
            top: 80,
            right: 16,
            child: _buildFocusControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildAROverlay() {
    if (_arDataList.isEmpty) return const SizedBox.shrink();
    
    return CustomPaint(
      painter: AROverlayPainter(
        arDataList: _arDataList,
        allShelfBooks: _expectedShelfBooks,
      ),
      child: SizedBox.expand(
        child: GestureDetector(
          onTap: () {
            // Permettre de cliquer sur des livres pour plus de détails
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.book, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _scanStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_detectedBarcodes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_detectedBarcodes.length}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_detectedBarcodes.isEmpty) {
      return Container(
        color: Colors.black.withValues(alpha: 0.9),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.cyan, size: 50),
            const SizedBox(height: 12),
            const Text(
              'امسح باركود الكتب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Liste des livres détectés
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _arDataList.length,
              itemBuilder: (context, index) {
                final arData = _arDataList[index];
                final statusColor = arData.arOverlay.colorValue;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Color(statusColor).withValues(alpha: 0.2),
                      border: Border.all(
                        color: Color(statusColor),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arData.book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              arData.arOverlay.badgeSymbol,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'الموقع: ${arData.currentPosition}/${arData.expectedPosition}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Affichage du guide de correction
          if (_correctionGuide != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _correctionGuide!.isInCorrectOrder
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _correctionGuide!.isInCorrectOrder
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _correctionGuide!.accuracyDescription,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_correctionGuide!.isInCorrectOrder)
                        Text(
                          'تم العثور على ${_correctionGuide!.totalErrorsFound} خطأ',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  if (!_correctionGuide!.isInCorrectOrder)
                    ElevatedButton(
                      onPressed: _startCorrection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'تصحيح',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Painter pour l'overlay AR avec affichage en temps réel de l'ordre
class AROverlayPainter extends CustomPainter {
  final List<BookARData> arDataList;
  final List<ShelfBook>? allShelfBooks;

  AROverlayPainter({
    required this.arDataList,
    this.allShelfBooks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (arDataList.isEmpty) return;
    
    // Draw shelf layout showing book order in real-time
    _drawShelfLayout(canvas, size);
    
    // Draw individual book badges with positions
    for (final arData in arDataList) {
      _drawBookPositionBadge(canvas, size, arData);
    }
    
    // Draw shelf boundary
    final firstArData = arDataList.first;
    _drawShelfBoundary(canvas, size, firstArData);
  }
  
  void _drawShelfLayout(Canvas canvas, Size size) {
    // Draw shelf representation at bottom of screen
    final shelfStartY = size.height * 0.75; // 75% down the screen
    final shelfHeight = 80.0;
    final shelfWidth = size.width * 0.9;
    final shelfX = (size.width - shelfWidth) / 2;
    
    // Draw shelf background
    final shelfPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    
    final shelfRect = Rect.fromLTWH(shelfX, shelfStartY, shelfWidth, shelfHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shelfRect, const Radius.circular(8)),
      shelfPaint,
    );
    
    // Draw shelf border
    final borderPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(shelfRect, const Radius.circular(8)),
      borderPaint,
    );
    
    // Get all expected positions from shelf books
    final maxPosition = allShelfBooks != null && allShelfBooks!.isNotEmpty
        ? (allShelfBooks as List).map((b) => b.expectedPosition).reduce((a, b) => a > b ? a : b)
        : 30;
    
    // Draw position markers for detected books
    final bookSlotWidth = shelfWidth / math.max(maxPosition, 1);
    
    for (final arData in arDataList) {
      final slotX = shelfX + (arData.currentPosition - 1) * bookSlotWidth;
      final slotCenterX = slotX + bookSlotWidth / 2;
      
      // Draw current position indicator
      final currentPaint = Paint()
        ..color = arData.isInCorrectOrder 
            ? Colors.green.withValues(alpha: 0.6)
            : Colors.orange.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(slotX, shelfStartY, bookSlotWidth - 2, shelfHeight),
        currentPaint,
      );
      
      // Draw expected position indicator (if different)
      if (!arData.isInCorrectOrder) {
        final expectedX = shelfX + (arData.expectedPosition - 1) * bookSlotWidth;
        final expectedPaint = Paint()
          ..color = Colors.green.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        
        canvas.drawRect(
          Rect.fromLTWH(expectedX, shelfStartY, bookSlotWidth - 2, shelfHeight),
          expectedPaint,
        );
        
        // Draw arrow from current to expected
        _drawArrow(
          canvas,
          Offset(slotCenterX, shelfStartY + shelfHeight / 2),
          Offset(expectedX + bookSlotWidth / 2, shelfStartY + shelfHeight / 2),
          Colors.green,
        );
      }
      
      // Draw position number
      final positionText = arData.isInCorrectOrder
          ? '${arData.currentPosition}'
          : '${arData.currentPosition}→${arData.expectedPosition}';
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: positionText,
          style: TextStyle(
            color: arData.isInCorrectOrder ? Colors.white : Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          slotCenterX - textPainter.width / 2,
          shelfStartY + shelfHeight / 2 - textPainter.height / 2,
        ),
      );
    }
  }
  
  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawLine(start, end, paint);
    
    // Draw arrowhead
    final angle = (end - start).direction;
    final arrowLength = 8.0;
    final arrowAngle = 0.5;
    
    final arrowEnd1 = Offset(
      end.dx - arrowLength * math.cos(angle - arrowAngle),
      end.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    final arrowEnd2 = Offset(
      end.dx - arrowLength * math.cos(angle + arrowAngle),
      end.dy - arrowLength * math.sin(angle + arrowAngle),
    );
    
    canvas.drawLine(end, arrowEnd1, paint);
    canvas.drawLine(end, arrowEnd2, paint);
  }
  
  void _drawBookPositionBadge(Canvas canvas, Size size, BookARData arData) {
    // Draw book badge floating above shelf showing title and position
    final shelfY = size.height * 0.75;
    final badgeY = shelfY - 100;
    
    // Calculate badge position based on book position
    final maxPosition = allShelfBooks != null && allShelfBooks!.isNotEmpty
        ? (allShelfBooks as List).map((b) => b.expectedPosition).reduce((a, b) => a > b ? a : b)
        : 30;
    final shelfWidth = size.width * 0.9;
    final shelfX = (size.width - shelfWidth) / 2;
    final bookSlotWidth = shelfWidth / math.max(maxPosition, 1);
    final slotX = shelfX + (arData.currentPosition - 1) * bookSlotWidth;
    final badgeX = slotX + bookSlotWidth / 2 - 80;
    
    // Draw badge background
    final badgeRect = Rect.fromLTWH(badgeX, badgeY, 160, 80);
    final badgePaint = Paint()
      ..color = Color(arData.arOverlay.colorValue).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)),
      badgePaint,
    );
    
    // Draw badge border
    final borderPaint = Paint()
      ..color = Color(arData.arOverlay.colorValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(8)),
      borderPaint,
    );
    
    // Draw book title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: arData.book.title.length > 20 
            ? '${arData.book.title.substring(0, 20)}...'
            : arData.book.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: 150);
    titlePainter.paint(canvas, Offset(badgeX + 5, badgeY + 5));
    
    // Draw position info
    final positionText = arData.isInCorrectOrder
        ? '✓ موقع ${arData.currentPosition}'
        : 'موقع ${arData.currentPosition} → ${arData.expectedPosition}';
    
    final positionPainter = TextPainter(
      text: TextSpan(
        text: positionText,
        style: TextStyle(
          color: arData.isInCorrectOrder ? Colors.white : Colors.orange.shade100,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    positionPainter.layout();
    positionPainter.paint(canvas, Offset(badgeX + 5, badgeY + 55));
    
    // Draw status icon
    final iconText = arData.arOverlay.badgeSymbol;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: iconText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(badgeX + 135, badgeY + 30));
    
    // Draw line connecting to shelf position
    final linePaint = Paint()
      ..color = Color(arData.arOverlay.colorValue).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final shelfConnectionX = slotX + bookSlotWidth / 2;
    canvas.drawLine(
      Offset(badgeX + 80, badgeY + 80),
      Offset(shelfConnectionX, shelfY),
      linePaint,
    );
  }

  void _drawShelfBoundary(Canvas canvas, Size size, BookARData arData) {
    final paint = Paint()
      ..color = Color(arData.arOverlay.colorValue).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Dessiner une boîte autour du rayon (approximation 2D)
    final shelfX = size.width / 2 - 60;
    final shelfY = size.height / 2 - 40;
    final shelfWidth = 120.0;
    final shelfHeight = 80.0;

    canvas.drawRect(
      Rect.fromLTWH(shelfX, shelfY, shelfWidth, shelfHeight),
      paint,
    );
  }


  @override
  bool shouldRepaint(AROverlayPainter oldDelegate) {
    return oldDelegate.arDataList != arDataList || 
           oldDelegate.allShelfBooks != allShelfBooks;
  }
}
