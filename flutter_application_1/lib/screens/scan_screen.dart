import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class ScanScreen extends StatefulWidget {
  final BookService bookService;
  final Function(Book) onBookScanned;

  const ScanScreen({
    super.key,
    required this.bookService,
    required this.onBookScanned,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    if (barcodeCapture.barcodes.isEmpty) return;
    final barcode = barcodeCapture.barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    final barcodeValue = barcode.rawValue!;

    // Vérifier si le livre est déjà scanné
    if (widget.bookService.isBarcodeScanned(barcodeValue)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الكتاب ممسوح مسبقاً'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    // Ajouter le livre
    final book = widget.bookService.addBook(barcodeValue);
    if (book != null) {
      widget.onBookScanned(book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم مسح الكتاب #${book.order ?? widget.bookService.totalScanned} بنجاح!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح الكتب'),
        backgroundColor: const Color(0xFF38ada9),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetect,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الكتب الممسوحة: ${widget.bookService.totalScanned}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'وجّه الكاميرا نحو باركود الكتاب',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha:0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38ada9)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

