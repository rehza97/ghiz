import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/floor.dart';
import '../models/library.dart';
import '../models/shelf.dart';
import '../services/dev_database_seed_service.dart';
import '../services/firebase_service.dart';

/// Écran d'informations sur la bibliothèque - local data + editable fields
class LibraryInfoScreen extends StatefulWidget {
  const LibraryInfoScreen({super.key, required this.library});

  final Library library;

  @override
  State<LibraryInfoScreen> createState() => _LibraryInfoScreenState();
}

class _LibraryInfoScreenState extends State<LibraryInfoScreen> {
  final FirebaseService _firebase = FirebaseService();
  static const String _developerSite = 'http://dataforgestack.com/';

  late Library _library;
  List<Floor> _floors = [];
  bool _loading = true;
  bool _seeding = false;
  String? _error;
  int _autoFillSeed = 0;

  @override
  void initState() {
    super.initState();
    _library = widget.library;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resolved = await _firebase.getLibraryById(_library.id);
      final floors = await _firebase.getFloorsByLibrary(_library.id);
      if (!mounted) return;
      setState(() {
        _library = resolved ?? widget.library;
        _floors = floors;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _seedFullDatabaseFromSettings() async {
    if (_seeding) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعبئة قاعدة البيانات'),
        content: const Text(
          'سيتم حذف البيانات المحلية الحالية واستبدالها ببيانات اختبار واقعية. المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _seeding = true);
    try {
      final summary = await DevDatabaseSeedService().seedFullDatabase();
      final libraries = await _firebase.getLibraries();
      if (!mounted) return;
      setState(() {
        if (libraries.isNotEmpty) {
          _library = libraries.first;
        }
      });
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت تعبئة قاعدة البيانات: ${summary.books} كتاب'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل تعبئة قاعدة البيانات: $e')));
    } finally {
      if (mounted) {
        setState(() => _seeding = false);
      }
    }
  }

  Future<void> _editLibraryDetails() async {
    final name = TextEditingController(text: _library.name);
    final description = TextEditingController(text: _library.description ?? '');
    final address = TextEditingController(text: _library.address);
    final postalCode = TextEditingController(text: _library.postalCode);
    final city = TextEditingController(text: _library.city);
    final phone = TextEditingController(text: _library.phone ?? '');
    final email = TextEditingController(text: _library.email ?? '');
    final hours = TextEditingController(text: _library.hours ?? '');
    final floorCount = TextEditingController(
      text: _library.floorCount.toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل معلومات المكتبة'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _input(name, 'اسم المكتبة'),
                  _input(description, 'الوصف'),
                  _input(address, 'العنوان'),
                  _input(postalCode, 'الرمز البريدي'),
                  _input(city, 'المدينة'),
                  _input(phone, 'الهاتف'),
                  _input(email, 'البريد الإلكتروني'),
                  _input(hours, 'أوقات العمل'),
                  _input(
                    floorCount,
                    'عدد الطوابق',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (kDebugMode)
              TextButton.icon(
                onPressed: () {
                  _autoFillSeed++;
                  name.text = 'مكتبة $_autoFillSeed';
                  description.text = 'وصف تجريبي $_autoFillSeed';
                  address.text = 'عنوان $_autoFillSeed';
                  postalCode.text = (10000 + _autoFillSeed).toString();
                  city.text = 'مدينة $_autoFillSeed';
                  phone.text =
                      '+21355${(_autoFillSeed % 10000000).toString().padLeft(7, '0')}';
                  email.text = 'lib$_autoFillSeed@test.local';
                  hours.text = '08:00 - 18:00';
                  floorCount.text = (1 + (_autoFillSeed % 5)).toString();
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
        );
      },
    );

    if (saved != true) return;

    final updated = _library.copyWith(
      name: name.text.trim().isEmpty ? _library.name : name.text.trim(),
      description: description.text.trim().isEmpty
          ? null
          : description.text.trim(),
      address: address.text.trim().isEmpty
          ? _library.address
          : address.text.trim(),
      postalCode: postalCode.text.trim().isEmpty
          ? _library.postalCode
          : postalCode.text.trim(),
      city: city.text.trim().isEmpty ? _library.city : city.text.trim(),
      phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
      email: email.text.trim().isEmpty ? null : email.text.trim(),
      hours: hours.text.trim().isEmpty ? null : hours.text.trim(),
      floorCount: int.tryParse(floorCount.text.trim()) ?? _library.floorCount,
    );

    await _firebase.saveLibrary(updated);
    if (!mounted) return;
    setState(() => _library = updated);
  }

  Future<void> _openDeveloperSite() async {
    await _copyDeveloperSite();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط الموقع. افتحه في المتصفح')),
    );
  }

  Future<void> _copyDeveloperSite() async {
    await Clipboard.setData(const ClipboardData(text: _developerSite));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الرابط')));
  }

  Future<void> _editFloor(Floor floor) async {
    final name = TextEditingController(text: floor.name);
    final description = TextEditingController(text: floor.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل الطابق'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _input(name, 'اسم الطابق'),
                _input(description, 'الوصف'),
              ],
            ),
          ),
          actions: [
            if (kDebugMode)
              TextButton.icon(
                onPressed: () {
                  _autoFillSeed++;
                  name.text = 'طابق $_autoFillSeed';
                  description.text = 'وصف طابق $_autoFillSeed';
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
        );
      },
    );

    if (saved != true) return;
    await _firebase.saveFloor(
      floor.copyWith(
        name: name.text.trim().isEmpty ? floor.name : name.text.trim(),
        description: description.text.trim().isEmpty
            ? null
            : description.text.trim(),
      ),
    );
    await _loadAll();
  }

  Future<void> _editShelf(Shelf shelf) async {
    final name = TextEditingController(text: shelf.name);
    final category = TextEditingController(text: shelf.category ?? '');
    final capacity = TextEditingController(text: shelf.capacity.toString());
    final count = TextEditingController(text: shelf.currentCount.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل الرف'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _input(name, 'اسم الرف'),
                _input(category, 'التصنيف'),
                _input(capacity, 'السعة', keyboardType: TextInputType.number),
                _input(
                  count,
                  'العدد الحالي',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            if (kDebugMode)
              TextButton.icon(
                onPressed: () {
                  _autoFillSeed++;
                  name.text = 'رف $_autoFillSeed';
                  category.text = 'تصنيف $_autoFillSeed';
                  capacity.text = (20 + (_autoFillSeed % 80)).toString();
                  count.text = (_autoFillSeed % 20).toString();
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
        );
      },
    );

    if (saved != true) return;
    await _firebase.saveShelf(
      shelf.copyWith(
        name: name.text.trim().isEmpty ? shelf.name : name.text.trim(),
        category: category.text.trim().isEmpty ? null : category.text.trim(),
        capacity: int.tryParse(capacity.text.trim()) ?? shelf.capacity,
        currentCount: int.tryParse(count.text.trim()) ?? shelf.currentCount,
      ),
    );
    await _loadAll();
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = _library;

    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات'),
        backgroundColor: const Color(0xFF38ada9),
        actions: [
          IconButton(
            onPressed: _seeding ? null : _seedFullDatabaseFromSettings,
            icon: _seeding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.data_array_outlined),
            tooltip: 'Quick Test Data',
          ),
          IconButton(
            onPressed: _editLibraryDetails,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'العنوان',
                    children: [
                      Text(library.address),
                      const SizedBox(height: 4),
                      Text(
                        '${library.postalCode} ${library.city}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'التواصل',
                    children: [
                      if (library.phone != null) ...[
                        Text(
                          library.phone!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                  _buildInfoCard(
                    icon: Icons.analytics,
                    title: 'معلومات',
                    children: [
                      _statRow('الطوابق (مسجلة)', '${library.floorCount}'),
                      _statRow('الطوابق (حالياً)', '${_floors.length}'),
                    ],
                  ),
                ],
              ),
            ),
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
                        child: CircularProgressIndicator(
                          color: Color(0xFF38ada9),
                        ),
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadAll,
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
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _floors.map(_buildFloorCardAsync).toList(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInfoCard(
                icon: Icons.developer_mode_outlined,
                title: 'Developer',
                children: [
                  const Text(
                    'DataForgeStack',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _openDeveloperSite,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'http://dataforgestack.com/',
                        style: TextStyle(
                          color: Color(0xFF38ada9),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _copyDeveloperSite,
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: const Text('نسخ الرابط'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _openDeveloperSite,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('فتح الموقع'),
                      ),
                    ],
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
                child: Icon(icon, color: const Color(0xFF38ada9), size: 20),
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
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
      future: _firebase.getShelvesByFloor(_library.id, floor.id),
      builder: (context, snapshot) {
        final shelves = snapshot.data ?? [];
        return _buildFloorCard(floor, shelves);
      },
    );
  }

  Widget _buildFloorCard(Floor floor, List<Shelf> shelves) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          floor.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          shelves.length == 1 ? 'رف واحد' : '${shelves.length} رفوف',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editFloor(floor),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل الطابق'),
                    ),
                  ],
                ),
                if (floor.description != null &&
                    floor.description!.isNotEmpty) ...[
                  Text(
                    floor.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                ],
                if (shelves.isEmpty)
                  Text(
                    'لا توجد رفوف',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: shelves.map((shelf) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shelf.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (shelf.category != null &&
                                      shelf.category!.isNotEmpty)
                                    Text(
                                      shelf.category!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
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
                            IconButton(
                              onPressed: () => _editShelf(shelf),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'تعديل الرف',
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
