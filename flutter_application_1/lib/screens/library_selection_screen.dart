import 'package:flutter/material.dart';
import '../models/library.dart';
import '../services/firebase_service.dart';
import 'dashboard_screen.dart';

/// Écran de sélection de la bibliothèque (point d'entrée) - données depuis Firebase
class LibrarySelectionScreen extends StatefulWidget {
  const LibrarySelectionScreen({super.key});

  @override
  State<LibrarySelectionScreen> createState() => _LibrarySelectionScreenState();
}

class _LibrarySelectionScreenState extends State<LibrarySelectionScreen> {
  String? selectedWilaya;
  final FirebaseService _firebase = FirebaseService();
  List<Library> _libraries = [];
  bool _loading = true;
  String? _error;

  // قائمة الولايات الجزائرية
  final List<String> wilayas = [
    'الكل',
    'Alger',
    'Oran',
    'Constantine',
    'Annaba',
    'Blida',
    'Sétif',
    'Batna',
    'Djelfa',
    'Sidi Bel Abbès',
    'Biskra',
    'Tébessa',
    'Tlemcen',
    'Béjaïa',
    'Bordj Bou Arréridj',
    'Boumerdès',
    'Tamanrasset',
    'Jijel',
    'Relizane',
    'Souk Ahras',
    'Tipaza',
    'Mila',
    'Aïn Defla',
    'Naâma',
    'Aïn Témouchent',
    'Ghardaïa',
    'Mostaganem',
    'Mascara',
    'M\'Sila',
    'Médéa',
    'Ouargla',
    'Oum El Bouaghi',
    'Guelma',
    'El Tarf',
    'Laghouat',
    'Ouled Djellal',
    'Bordj Badji Mokhtar',
    'Béni Abbès',
    'In Salah',
    'In Guezzam',
    'Touggourt',
    'Djanet',
    'El M\'Ghair',
    'El Menia',
    'Timimoun',
    'Adrar',
    'Chlef',
    'Béchar',
    'Bouira',
    'Tiaret',
    'Tizi Ouzou',
    'Saïda',
    'Skikda',
    'Tindouf',
    'Tissemsilt',
    'El Oued',
    'Khenchela',
    'Illizi',
    'El Bayadh',
  ];

  List<Library> get filteredLibraries {
    if (selectedWilaya == null || selectedWilaya == 'الكل') {
      return _libraries;
    }
    return _libraries
        .where((lib) => lib.city == selectedWilaya)
        .toList();
  }

  Future<void> _loadLibraries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final wilaya = (selectedWilaya == null || selectedWilaya == 'الكل')
          ? null
          : selectedWilaya;
      final list = await _firebase.getLibraries(wilaya: wilaya);
      if (mounted) {
        setState(() {
          _libraries = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _libraries = [];
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLibraries();
  }

  @override
  void didUpdateWidget(covariant LibrarySelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final libraries = filteredLibraries;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec logo/titre
          SliverAppBar(
            expandedHeight: 360,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF38ada9),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                'ماسح الكتب بالواقع المعزز',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF38ada9), Color(0xFF3c6382)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.library_books,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'مرحباً',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'اختر مكتبتك',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filtre par wilaya - Row scrollable
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: wilayas.length,
                itemBuilder: (context, index) {
                  final wilaya = wilayas[index];
                  final isSelected =
                      selectedWilaya == wilaya ||
                      (selectedWilaya == null && wilaya == 'الكل');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        wilaya,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (wilaya == 'الكل') {
                            selectedWilaya = null;
                          } else if (selected) {
                            selectedWilaya = wilaya;
                          } else {
                            selectedWilaya = null;
                          }
                        });
                        _loadLibraries();
                      },
                      selectedColor: const Color(0xFF38ada9),
                      backgroundColor: Colors.grey[200],
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      elevation: isSelected ? 2 : 0,
                      pressElevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF38ada9)
                              : Colors.grey[300]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Liste des bibliothèques (ou chargement / erreur)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _loading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF38ada9)),
                      ),
                    ),
                  )
                : _error != null
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'خطأ في التحميل',
                                style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadLibraries,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38ada9)),
                                child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : libraries.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'لا توجد مكتبات حالياً.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final library = libraries[index];
                              return _buildLibraryCard(context, library);
                            }, childCount: libraries.length),
                          ),
          ),

          // Espacement en bas
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(BuildContext context, Library library) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          _selectLibrary(context, library);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF38ada9).withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF38ada9).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône et nom
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF38ada9), Color(0xFF3c6382)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38ada9).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          library.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.layers,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              library.floorCount == 1 ? 'طابق واحد' : '${library.floorCount} طوابق',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF38ada9,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                library.city,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF38ada9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38ada9).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF38ada9),
                      size: 18,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Adresse
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.map, size: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${library.address}, ${library.postalCode} ${library.city}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contact
              if (library.phone != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      library.phone!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              if (library.phone != null) const SizedBox(height: 16),

              // Horaires
              if (library.hours != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF38ada9).withValues(alpha: 0.1),
                        const Color(0xFF3c6382).withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF38ada9).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38ada9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          size: 16,
                          color: Color(0xFF38ada9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          library.hours!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3c6382),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLibrary(BuildContext context, Library library) {
    // Animation de sélection
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF38ada9),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'مرحباً بك في',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  library.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fermer le dialog
                      // Naviguer vers le dashboard
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              DashboardScreen(library: library),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38ada9),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'متابعة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
    );
  }
}
