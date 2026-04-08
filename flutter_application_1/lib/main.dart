import 'dart:async';

import 'package:flutter/material.dart';
import 'models/library.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/librarian_onboarding_screen.dart';
import 'services/dev_database_seed_service.dart';
import 'services/firebase_service.dart';
import 'services/local_librarian_profile_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final LocalLibrarianProfileService _profileService =
      LocalLibrarianProfileService();
  final FirebaseService _firebase = FirebaseService();

  late Future<LibrarianProfile?> _profileFuture;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _profileFuture = _initializeProfile();
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  Future<LibrarianProfile?> _initializeProfile() async {
    await maybeSeedFullDatabaseOnStartup();
    return _profileService.getProfile();
  }

  void _markOnboardingCompleted() {
    setState(() {
      _profileFuture = _profileService.getProfile();
    });
  }

  Future<Library> _resolveInitialLibrary(LibrarianProfile profile) async {
    final libraries = await _firebase.getLibraries();
    final normalizedProfileLibrary = profile.libraryName.trim().toLowerCase();
    for (final library in libraries) {
      if (library.name.trim().toLowerCase() == normalizedProfileLibrary) {
        return library;
      }
    }

    final localId = 'lib_local_${profile.email.hashCode.abs()}';
    final created = Library(
      id: localId,
      name: profile.libraryName.trim(),
      address: 'عنوان محلي',
      postalCode: '00000',
      city: 'Local',
      phone: profile.phone,
      email: profile.email,
      floorCount: 0,
      latitude: 0,
      longitude: 0,
      description: 'مكتبة محلية',
    );
    await _firebase.saveLibrary(created);
    return created;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق DocShelf Eye: تطبيق ذكي لإدارة الأرصدة الوثائقية',
      theme: ThemeData(
        primaryColor: const Color(0xFF38ada9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38ada9),
          secondary: const Color(0xFF3c6382),
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<LibrarianProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (_showSplash) {
            return const SplashScreen();
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return LibrarianOnboardingScreen(
              onCompleted: _markOnboardingCompleted,
            );
          }

          return FutureBuilder<Library>(
            future: _resolveInitialLibrary(profile),
            builder: (context, librarySnapshot) {
              if (!librarySnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return DashboardScreen(
                library: librarySnapshot.data!,
                librarianProfile: profile,
              );
            },
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
