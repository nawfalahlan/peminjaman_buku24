import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'models/member.dart';
import 'screens/login_screen.dart';
import 'screens/member/member_home.dart';
import 'screens/staff/staff_home.dart';
import 'services/library_repository.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web tidak punya dart:io, jadi pakai penyimpanan browser.
  var repo = LibraryRepository(kIsWeb ? WebStorage() : FileStorage());
  try {
    await repo.init();
  } catch (e) {
    // Jangan sampai layar kosong: pakai memori bila penyimpanan gagal.
    debugPrint('Gagal memuat penyimpanan: $e');
    repo = LibraryRepository(MemoryStorage());
    await repo.init();
  }
  runApp(LibraryApp(repo: repo));
}

/// Root aplikasi: menampilkan layar sesuai hak akses (login / petugas / anggota).
class LibraryApp extends StatelessWidget {
  final LibraryRepository repo;
  const LibraryApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perpustakaan Sekolah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: repo,
        builder: (context, _) {
          final s = repo.session;
          if (s == null) return LoginScreen(repo: repo);
          return s.role == Role.staff
              ? StaffHome(repo: repo)
              : MemberHome(repo: repo);
        },
      ),
    );
  }
}
