import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/book_location.dart';
import '../models/book.dart';
import '../models/shelf.dart';
import '../services/firebase_service.dart';

// ─── Result model ────────────────────────────────────────────────────────────

class _ScannedResult {
  final Book book;
  final BookLocation? location;
  final bool isCorrectShelf;
  final String? wrongShelfName; // name of the shelf it actually belongs to

  _ScannedResult({
    required this.book,
    required this.location,
    required this.isCorrectShelf,
    this.wrongShelfName,
  });
}

enum _ScannerQualityMode { balanced, high }

// ─── Screen ──────────────────────────────────────────────────────────────────

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

class _ARBookDetectionScreenState extends State<ARBookDetectionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  final FirebaseService _firebase = FirebaseService();
  _ScannerQualityMode _qualityMode = _ScannerQualityMode.high;

  Shelf? _shelf;
  final List<String> _scannedIsbns = [];
  final List<_ScannedResult> _scannedResults = [];

  DateTime? _lastScanTime;
  bool _isFocusing = false;
  Offset? _focusPoint;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = _createScannerController(_qualityMode);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadShelf();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  MobileScannerController _createScannerController(_ScannerQualityMode mode) {
    final isHigh = mode == _ScannerQualityMode.high;
    return MobileScannerController(
      // DetectionSpeed.normal allows multiple barcodes per frame.
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.all],
      cameraResolution: isHigh ? const Size(1920, 1080) : const Size(1280, 720),
      autoZoom: isHigh,
      torchEnabled: false,
      autoStart: true,
    );
  }

  Future<void> _setQualityMode(_ScannerQualityMode mode) async {
    if (_qualityMode == mode) return;
    await _scannerController.stop();
    await _scannerController.dispose();
    if (!mounted) return;
    setState(() {
      _qualityMode = mode;
      _scannerController = _createScannerController(mode);
    });
  }

  Future<void> _loadShelf() async {
    final shelf = await _firebase.getShelfByLibraryAndShelfId(
      widget.libraryId,
      widget.shelfId,
    );
    if (mounted) setState(() => _shelf = shelf);
  }

  // ── Barcode handling ───────────────────────────────────────────────────────

  Future<void> _handleBarcode(BarcodeCapture barcodes) async {
    if (barcodes.barcodes.isEmpty) return;

    // Debounce: skip frames that arrive too fast but always process
    // frames that contain NEW barcodes not yet seen.
    final now = DateTime.now();
    final tooSoon =
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 300;

    // Collect new codes from this frame
    final newCodes = <String>[];
    for (final barcode in barcodes.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final parsed = _parseBarcode(raw);
      final key = parsed.isbn.isNotEmpty ? parsed.isbn : raw;
      if (!_scannedIsbns.contains(key)) {
        newCodes.add(raw);
      }
    }

    if (newCodes.isEmpty) return; // all already scanned
    if (tooSoon) return; // throttle only when nothing new
    _lastScanTime = now;

    // Process all new barcodes from this frame in parallel
    await Future.wait(newCodes.map(_addScannedCode));
  }

  /// Parses a raw scanned value.
  /// Supports two formats:
  ///   - Plain ISBN:            "9785969710157"
  ///   - Composite (with shelf): "9785969710157 A-1"
  ///
  /// Returns (isbn, embeddedShelfName).
  ({String isbn, String? shelfCode}) _parseBarcode(String raw) {
    final trimmed = raw.replaceAll(RegExp(r'[\x00-\x1F]'), '').trim();

    // Composite: first token is all-digits ISBN, rest is shelf code
    final spaceIdx = trimmed.indexOf(' ');
    if (spaceIdx > 0) {
      final left = trimmed
          .substring(0, spaceIdx)
          .replaceAll(RegExp(r'[^0-9]'), '');
      final right = trimmed.substring(spaceIdx + 1).trim();
      if (RegExp(r'^\d{10}$|^\d{13}$').hasMatch(left) && right.isNotEmpty) {
        return (isbn: left, shelfCode: right);
      }
    }

    // Plain ISBN — strip dashes/spaces
    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return (isbn: cleaned, shelfCode: null);
  }

  bool _isValidIsbn13(String value) {
    if (!RegExp(r'^\d{13}$').hasMatch(value)) return false;
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final d = int.parse(value[i]);
      sum += i.isEven ? d : d * 3;
    }
    final check = (10 - (sum % 10)) % 10;
    return check == int.parse(value[12]);
  }

  bool _isValidIsbn10(String value) {
    if (!RegExp(r'^\d{9}[\dXx]$').hasMatch(value)) return false;
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += (10 - i) * int.parse(value[i]);
    }
    final last = value[9].toUpperCase() == 'X' ? 10 : int.parse(value[9]);
    sum += last;
    return sum % 11 == 0;
  }

  bool _isValidBookCode(String isbn) {
    return _isValidIsbn13(isbn) || _isValidIsbn10(isbn);
  }

  Future<void> _addScannedCode(String value) async {
    // ── Shelf barcode (SHELF:{id} label on the physical shelf) ────────────
    if (value.startsWith('SHELF:')) {
      _scannedIsbns.add(value);
      final shelfId = value.substring(6);
      final shelf = await _firebase.getShelfByLibraryAndShelfId(
        widget.libraryId,
        shelfId,
      );
      if (!mounted) return;
      final isThis = shelfId == widget.shelfId;
      _showSnack(
        isThis
            ? '✅ الرف الصحيح: ${shelf?.name ?? shelfId}'
            : '⚠️ هذا رف آخر: ${shelf?.name ?? shelfId}',
        isThis ? Colors.green : Colors.orange,
      );
      return;
    }

    // ── Book barcode (plain ISBN or composite "isbn shelfCode") ───────────
    final parsed = _parseBarcode(value);
    final isbn = parsed.isbn;
    final embeddedShelf = parsed.shelfCode; // e.g. "A-1" from composite label

    if (_scannedIsbns.contains(isbn)) return;
    if (!_isValidBookCode(isbn)) {
      if (kDebugMode) {
        debugPrint('⚠️ Ignored invalid barcode payload: "$value" -> "$isbn"');
      }
      return;
    }

    final book = await _firebase.getBookByIsbn(isbn);
    if (book == null) {
      if (kDebugMode) debugPrint('ℹ️ Book not found in DB: $isbn');
      _showSnack('هذا الباركود غير موجود في قاعدة البيانات', Colors.orange);
      return;
    }
    _scannedIsbns.add(isbn);

    bool isCorrect;
    String? wrongShelfName;
    BookLocation? location;

    if (embeddedShelf != null) {
      // ── Fast path: shelf code is baked into the barcode ─────────────────
      // Compare embedded shelf name directly against current shelf name.
      final currentShelfName = _shelf?.name ?? widget.shelfId;
      isCorrect = embeddedShelf == currentShelfName;
      if (!isCorrect) wrongShelfName = embeddedShelf;
    } else {
      // ── Slow path: look up location from DB ──────────────────────────────
      location = await _firebase.getBookLocation(isbn, widget.libraryId);
      isCorrect = location?.shelfId == widget.shelfId;
      if (!isCorrect && location != null) {
        final wrongShelf = await _firebase.getShelfByLibraryAndShelfId(
          widget.libraryId,
          location.shelfId,
        );
        wrongShelfName = wrongShelf?.name ?? location.shelfId;
      }
    }

    if (!mounted) return;
    HapticFeedback.lightImpact();
    // Persist the scan timestamp so ScannedBooksScreen can filter by it.
    unawaited(_firebase.markBookAsScanned(isbn));
    setState(() {
      _scannedResults.add(
        _ScannedResult(
          book: book,
          location: location,
          isCorrectShelf: isCorrect,
          wrongShelfName: wrongShelfName,
        ),
      );
    });
  }

  void _clear() {
    setState(() {
      _scannedIsbns.clear();
      _scannedResults.clear();
      _lastScanTime = null;
    });
  }

  // ── Focus / torch ──────────────────────────────────────────────────────────

  void _handleTap(TapDownDetails details) {
    setState(() {
      _focusPoint = details.localPosition;
      _isFocusing = true;
    });
    HapticFeedback.selectionClick();
    _scannerController.stop();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scannerController.start();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _isFocusing = false);
        });
      }
    });
  }

  void _toggleTorch() {
    _scannerController.toggleTorch();
    if (mounted) setState(() {});
  }

  void _triggerFocus() {
    setState(() => _isFocusing = true);
    HapticFeedback.selectionClick();
    _scannerController.stop();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scannerController.start();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _isFocusing = false);
        });
      }
    });
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final shelfName = _shelf?.name ?? '…';
    final correct = _scannedResults.where((r) => r.isCorrectShelf).length;
    final wrong = _scannedResults.where((r) => !r.isCorrectShelf).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('رف: $shelfName'),
        backgroundColor: const Color(0xFF38ada9),
        elevation: 0,
        actions: [
          PopupMenuButton<_ScannerQualityMode>(
            tooltip: 'جودة الكاميرا',
            icon: const Icon(Icons.hd_outlined),
            initialValue: _qualityMode,
            onSelected: _setQualityMode,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ScannerQualityMode.balanced,
                child: Text('Balanced'),
              ),
              const PopupMenuItem(
                value: _ScannerQualityMode.high,
                child: Text('High Quality'),
              ),
            ],
          ),
          if (_scannedResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clear,
              tooltip: 'إعادة تعيين',
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera ────────────────────────────────────────────────────
          GestureDetector(
            onTapDown: _handleTap,
            child: MobileScanner(
              key: ValueKey(_qualityMode),
              controller: _scannerController,
              onDetect: _handleBarcode,
              fit: BoxFit.cover,
              // No scanWindow — full camera frame is active so multiple
              // barcodes side-by-side (and any orientation) are all detected.
            ),
          ),

          // ── Scan guide ────────────────────────────────────────────────
          _buildScanGuide(),

          // ── Focus dot ─────────────────────────────────────────────────
          if (_focusPoint != null && _isFocusing)
            Positioned(
              left: _focusPoint!.dx - 35,
              top: _focusPoint!.dy - 35,
              child: AnimatedOpacity(
                opacity: _isFocusing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyan, width: 2),
                  ),
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: Colors.cyan,
                    size: 28,
                  ),
                ),
              ),
            ),

          // ── Top status chip ───────────────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 72,
            child: _buildStatusChip(correct, wrong),
          ),

          // ── Side controls ─────────────────────────────────────────────
          Positioned(
            top: 8,
            right: 12,
            child: Column(
              children: [
                _iconBtn(
                  _isFocusing
                      ? Icons.center_focus_strong
                      : Icons.center_focus_weak,
                  _isFocusing ? Colors.cyan : Colors.white,
                  _triggerFocus,
                ),
                const SizedBox(height: 8),
                _iconBtn(
                  _scannerController.torchEnabled
                      ? Icons.flash_on
                      : Icons.flash_off,
                  _scannerController.torchEnabled ? Colors.amber : Colors.white,
                  _toggleTorch,
                ),
              ],
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
        iconSize: 22,
      ),
    );
  }

  Widget _buildStatusChip(int correct, int wrong) {
    if (_scannedResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.6)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.cyan, size: 16),
            SizedBox(width: 6),
            Text(
              'وجّه الكاميرا نحو باركود الكتاب',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: wrong > 0 ? Colors.orange : Colors.greenAccent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (correct > 0) ...[
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 4),
            Text(
              '$correct',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (wrong > 0) ...[
            const Icon(Icons.warning_rounded, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text(
              '$wrong',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (_scannedResults.isEmpty) {
      return Container(
        color: Colors.black.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: Text(
            'لم يتم مسح أي كتاب بعد',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    // Show most recent on top
    final results = _scannedResults.reversed.toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.42,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: results.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, i) => _buildResultRow(results[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(_ScannedResult r) {
    final isOk = r.isCorrectShelf;
    final color = isOk ? Colors.greenAccent : Colors.orange;
    final icon = isOk ? Icons.check_circle : Icons.warning_rounded;

    // Badge shows the shelf this book actually belongs to
    final shelfBadge = isOk
        ? (_shelf?.name ?? '…')
        : (r.wrongShelfName ?? r.location?.shelfId ?? '؟');
    final badgeColor = isOk ? const Color(0xFF38ada9) : Colors.orange.shade700;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showScannedBookDetails(r),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              // Shelf badge — most important visual diff between correct/wrong
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  shelfBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showScannedBookDetails(_ScannedResult result) async {
    final location =
        result.location ??
        await _firebase.getBookLocation(result.book.isbn, widget.libraryId);
    if (!mounted) return;

    final floorName = location != null
        ? ((await _firebase.getFloorById(
                location.libraryId,
                location.floorId,
              ))?.name ??
              location.floorId)
        : 'غير محدد';
    final shelfName = location != null
        ? ((await _firebase.getShelfByLibraryAndShelfId(
                location.libraryId,
                location.shelfId,
              ))?.name ??
              location.shelfId)
        : (result.wrongShelfName ?? 'غير محدد');
    if (!mounted) return;

    final bool isCorrect = result.isCorrectShelf;
    final statusColor = isCorrect ? Colors.green : Colors.orange;
    final statusText = isCorrect ? 'في مكانه الصحيح' : 'ليس في مكانه الصحيح';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.warning_rounded,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow('ISBN', result.book.isbn),
              _detailRow('المؤلف', result.book.author),
              _detailRow('التصنيف', result.book.category),
              _detailRow('الطابق', floorName),
              _detailRow('الرف الصحيح', shelfName),
              if (location != null) ...[
                _detailRow('الموقع الحالي', '${location.position}'),
                _detailRow('الموقع المتوقع', '${location.expectedPosition}'),
              ],
              if (!isCorrect)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'الإجراء: انقل الكتاب إلى الرف $shelfName'
                      '${location != null ? ' (الموقع ${location.expectedPosition})' : ''}.',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanGuide() {
    return IgnorePointer(
      child: Align(
        // Horizontal band across the middle of the camera — matches how
        // you hold the phone to sweep across a row of books on a shelf.
        alignment: const Alignment(0, -0.15),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _pulseAnimation.value, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF38ada9).withValues(alpha: 0.9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38ada9).withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corner accents (top-left, top-right, bottom-left, bottom-right)
                  for (final align in [
                    Alignment.topLeft,
                    Alignment.topRight,
                    Alignment.bottomLeft,
                    Alignment.bottomRight,
                  ])
                    Align(
                      alignment: align,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          border: Border(
                            top: align.y < 0
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : BorderSide.none,
                            bottom: align.y > 0
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : BorderSide.none,
                            left: align.x < 0
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : BorderSide.none,
                            right: align.x > 0
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  // Label
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'وجّه الكاميرا نحو صف الكتب — يقرأ عدة باركود دفعة واحدة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
