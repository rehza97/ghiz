import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/local_librarian_profile_service.dart';

class LibrarianOnboardingScreen extends StatefulWidget {
  const LibrarianOnboardingScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<LibrarianOnboardingScreen> createState() =>
      _LibrarianOnboardingScreenState();
}

class _LibrarianOnboardingScreenState extends State<LibrarianOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _libraryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _service = LocalLibrarianProfileService();

  bool _saving = false;
  int _autoFillSeed = 0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _libraryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    try {
      await _service.saveProfile(
        LibrarianProfile(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          libraryName: _libraryController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        ),
      );
      if (!mounted) return;
      widget.onCompleted();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _autoFillForDev() {
    _autoFillSeed++;
    _fullNameController.text = 'Test Librarian $_autoFillSeed';
    _emailController.text = 'librarian.$_autoFillSeed@docshelf.local';
    _libraryController.text = 'Bibliotheque Test $_autoFillSeed';
    _phoneController.text =
        '+21355${(_autoFillSeed % 10000000).toString().padLeft(7, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تهيئة التطبيق'),
        backgroundColor: const Color(0xFF38ada9),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'المرة الأولى فقط: أدخل معلومات أمين المكتبة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم الكامل مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'البريد الإلكتروني مطلوب';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'صيغة البريد الإلكتروني غير صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _libraryController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المكتبة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اسم المكتبة مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                if (kDebugMode) ...[
                  OutlinedButton.icon(
                    onPressed: _autoFillForDev,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Auto Fill (Dev)'),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF38ada9),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حفظ والبدء'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
