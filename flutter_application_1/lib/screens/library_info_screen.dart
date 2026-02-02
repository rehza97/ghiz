import 'package:flutter/material.dart';
import '../models/library.dart';
import '../models/floor.dart';
import '../models/shelf.dart';
import '../services/firebase_service.dart';

/// Écran d'informations sur la bibliothèque - données depuis Firebase
class LibraryInfoScreen extends StatefulWidget {
  final Library library;

  const LibraryInfoScreen({
    super.key,
    required this.library,
  });

  @override
  State<LibraryInfoScreen> createState() => _LibraryInfoScreenState();
}

class _LibraryInfoScreenState extends State<LibraryInfoScreen> {
  final FirebaseService _firebase = FirebaseService();
  List<Floor> _floors = [];
  bool _loading = true;
  String? _error;

  Future<void> _loadFloors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _firebase.getFloorsByLibrary(widget.library.id);
      if (mounted) {
        setState(() {
          _floors = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _floors = [];
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFloors();
  }

  @override
  Widget build(BuildContext context) {
    final library = widget.library;

    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات'),
        backgroundColor: const Color(0xFF38ada9),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.library_books,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    library.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (library.description != null)
                    Text(
                      library.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            // Main info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Location Card
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'العنوان',
                    children: [
                      Text(library.address),
                      const SizedBox(height: 4),
                      Text(
                        '${library.postalCode} ${library.city}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Contact Card
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'التواصل',
                    children: [
                      if (library.phone != null) ...[
                        Text(
                          library.phone!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (library.email != null)
                        Text(
                          library.email!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF38ada9),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hours Card
                  if (library.hours != null)
                    _buildInfoCard(
                      icon: Icons.schedule,
                      title: 'أوقات العمل',
                      children: [
                        Text(
                          library.hours!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  if (library.hours != null) const SizedBox(height: 12),

                  // Stats Card
                  _buildInfoCard(
                    icon: Icons.analytics,
                    title: 'معلومات',
                    children: [
                      _statRow('الطوابق', '${_floors.length}'),
                    ],
                  ),
                ],
              ),
            ),

            // Floors section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الطوابق',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF38ada9)),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Text(
                              'خطأ: $_error',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadFloors,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_floors.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'لم يتم العثور على طوابق',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _floors.map((floor) {
                        return _buildFloorCardAsync(floor);
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF38ada9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF38ada9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorCardAsync(Floor floor) {
    return FutureBuilder<List<Shelf>>(
      future: _firebase.getShelvesByFloor(widget.library.id, floor.id),
      builder: (context, snapshot) {
        final shelves = snapshot.data ?? [];
        return _buildFloorCard(floor, shelves);
      },
    );
  }

  Widget _buildFloorCard(Floor floor, List<Shelf> shelves) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          floor.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          shelves.length == 1 ? 'رف واحد' : '${shelves.length} رفوف',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (floor.description != null && floor.description!.isNotEmpty) ...[
                  Text(
                    floor.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                ],
                if (shelves.isEmpty)
                  Text(
                    'لا توجد رفوف',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: shelves.map((shelf) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shelf.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                if (shelf.category != null && shelf.category!.isNotEmpty)
                                  Text(
                                    shelf.category!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${shelf.currentCount}/${shelf.capacity}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
