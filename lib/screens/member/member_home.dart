import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../models/loan.dart';
import '../../services/library_repository.dart';
import '../../utils/format.dart';
import '../../utils/ui_helpers.dart';

/// Beranda anggota: Katalog, Pinjaman Saya (+pengingat), Riwayat.
class MemberHome extends StatefulWidget {
  final LibraryRepository repo;
  const MemberHome({super.key, required this.repo});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> {
  int _index = 0;
  static const _titles = ['Katalog Buku', 'Pinjaman Saya', 'Riwayat'];

  @override
  Widget build(BuildContext context) {
    final r = widget.repo;
    final me = r.session!;
    final pages = <Widget>[
      _CatalogPage(repo: r, memberId: me.userId),
      _MyLoansPage(repo: r, memberId: me.userId),
      _HistoryPage(repo: r, memberId: me.userId),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Center(child: Text(me.name)),
          IconButton(
              tooltip: 'Keluar', icon: const Icon(Icons.logout), onPressed: r.logout),
        ],
      ),
      body: Column(children: [
        _ReminderBanner(repo: r, memberId: me.userId),
        Expanded(child: IndexedStack(index: _index, children: pages)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Katalog'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Pinjaman'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}

/// Pengingat batas waktu pengembalian (jatuh tempo <= 2 hari / terlambat).
class _ReminderBanner extends StatelessWidget {
  final LibraryRepository repo;
  final String memberId;
  const _ReminderBanner({required this.repo, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final list = repo.remindersFor(memberId);
        if (list.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: Colors.amber.shade100,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.alarm, size: 18),
                SizedBox(width: 6),
                Text('Pengingat pengembalian',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              for (final l in list) Text(_text(l)),
            ],
          ),
        );
      },
    );
  }

  String _text(Loan l) {
    final left = FineCalculator.daysLeft(l.dueDate!, repo.now);
    final title = repo.bookById(l.bookId)?.title ?? '(buku dihapus)';
    if (left < 0) {
      return '• $title terlambat ${-left} hari (denda ${rupiah(-left * LoanRules.finePerDay)})';
    }
    if (left == 0) return '• $title jatuh tempo HARI INI';
    return '• $title jatuh tempo $left hari lagi (${fmtDate(l.dueDate)})';
  }
}

class _CatalogPage extends StatefulWidget {
  final LibraryRepository repo;
  final String memberId;
  const _CatalogPage({required this.repo, required this.memberId});

  @override
  State<_CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<_CatalogPage> {
  String _query = '';
  String? _category;
  bool _onlyAvailable = false;

  Future<void> _request(Book b) async {
    if (!await confirm(context, 'Ajukan peminjaman "${b.title}"?',
        okLabel: 'Ajukan')) {
      return;
    }
    if (!mounted) return;
    guard(context, () => widget.repo.requestLoan(widget.memberId, b.id),
        success: 'Pengajuan terkirim, menunggu persetujuan petugas');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final cats = widget.repo.categories;
        final list = widget.repo.searchBooks(
            query: _query, category: _category, onlyAvailable: _onlyAvailable);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: searchField((v) => setState(() => _query = v),
                hint: 'Cari judul / pengarang / penerbit'),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tersedia'),
                    selected: _onlyAvailable,
                    onSelected: (v) => setState(() => _onlyAvailable = v),
                  ),
                ),
                for (final c in cats)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (v) =>
                          setState(() => _category = v ? c : null),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? emptyState('Buku tidak ditemukan')
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final b = list[i];
                      return ListTile(
                        title: Text(b.title),
                        subtitle: Text(
                            '${b.author} • ${b.publisher}\n${b.category} • Rak ${b.shelf}'),
                        isThreeLine: true,
                        trailing: b.stock > 0
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Stok ${b.stock}',
                                      style: const TextStyle(fontSize: 12)),
                                  SizedBox(
                                    height: 32,
                                    child: FilledButton(
                                      onPressed: () => _request(b),
                                      child: const Text('Ajukan'),
                                    ),
                                  ),
                                ],
                              )
                            : const Text('Habis',
                                style: TextStyle(color: Colors.red)),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}

class _MyLoansPage extends StatelessWidget {
  final LibraryRepository repo;
  final String memberId;
  const _MyLoansPage({required this.repo, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final list =
            repo.loansOfMember(memberId).where((l) => l.isActive).toList();
        if (list.isEmpty) return emptyState('Tidak ada pinjaman aktif');
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final l = list[i];
            final title = repo.bookById(l.bookId)?.title ?? '(buku dihapus)';
            if (l.status == LoanStatus.requested) {
              return ListTile(
                title: Text(title),
                subtitle: Text('Menunggu persetujuan • ${fmtDate(l.requestDate)}'),
                trailing: TextButton(
                  onPressed: () => guard(context, () => repo.cancelRequest(l.id),
                      success: 'Pengajuan dibatalkan'),
                  child: const Text('Batalkan'),
                ),
              );
            }
            final left = FineCalculator.daysLeft(l.dueDate!, repo.now);
            return ListTile(
              title: Text(title),
              subtitle: Text(
                'Dipinjam ${fmtDate(l.loanDate)} • Tempo ${fmtDate(l.dueDate)}\n'
                '${left < 0 ? 'Terlambat ${-left} hari' : 'Sisa $left hari'}',
                style: TextStyle(color: left < 0 ? Colors.red : null),
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}

class _HistoryPage extends StatelessWidget {
  final LibraryRepository repo;
  final String memberId;
  const _HistoryPage({required this.repo, required this.memberId});

  String _label(Loan l) {
    switch (l.status) {
      case LoanStatus.requested:
        return 'Diajukan';
      case LoanStatus.borrowed:
        return 'Dipinjam';
      case LoanStatus.returned:
        return 'Dikembalikan ${fmtDate(l.returnDate)}'
            '${l.fine > 0 ? ' • denda ${rupiah(l.fine)}' : ''}';
      case LoanStatus.rejected:
        return 'Ditolak / dibatalkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final list = repo.loansOfMember(memberId);
        if (list.isEmpty) return emptyState('Belum ada riwayat peminjaman');
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            title: Text(repo.bookById(list[i].bookId)?.title ?? '(buku dihapus)'),
            subtitle: Text(_label(list[i])),
          ),
        );
      },
    );
  }
}
