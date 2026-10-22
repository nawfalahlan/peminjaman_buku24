import 'package:flutter/material.dart';

import '../../services/library_repository.dart';
import 'books_tab.dart';
import 'circulation_tab.dart';
import 'members_tab.dart';
import 'report_tab.dart';

/// Beranda petugas dengan 4 menu: Buku, Anggota, Sirkulasi, Laporan.
class StaffHome extends StatefulWidget {
  final LibraryRepository repo;
  const StaffHome({super.key, required this.repo});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _index = 0;

  static const _titles = ['Data Buku', 'Data Anggota', 'Sirkulasi', 'Laporan'];

  @override
  Widget build(BuildContext context) {
    final r = widget.repo;
    final tabs = <Widget>[
      BooksTab(repo: r),
      MembersTab(repo: r),
      CirculationTab(repo: r),
      ReportTab(repo: r),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: r.logout,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Buku'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Anggota'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Sirkulasi'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }
}
