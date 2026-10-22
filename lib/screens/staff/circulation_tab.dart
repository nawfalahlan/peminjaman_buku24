import 'package:flutter/material.dart';

import '../../models/loan.dart';
import '../../services/library_repository.dart';
import '../../utils/format.dart';
import '../../utils/ui_helpers.dart';

/// Pemrosesan sirkulasi: pengajuan, peminjaman, pengembalian + denda.
class CirculationTab extends StatelessWidget {
  final LibraryRepository repo;
  const CirculationTab({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _borrowDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Pinjam'),
        ),
        body: Column(
          children: [
            const TabBar(tabs: [Tab(text: 'Pengajuan'), Tab(text: 'Dipinjam')]),
            Expanded(
              child: ListenableBuilder(
                listenable: repo,
                builder: (context, _) => TabBarView(children: [
                  _requests(context),
                  _borrowed(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requests(BuildContext context) {
    final list = repo.loansByStatus(LoanStatus.requested);
    if (list.isEmpty) return emptyState('Tidak ada pengajuan');
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final l = list[i];
        return ListTile(
          title: Text(repo.bookById(l.bookId)?.title ?? '(buku dihapus)'),
          subtitle: Text(
              '${repo.memberById(l.memberId)?.name ?? '-'} • diajukan ${fmtDate(l.requestDate)}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'Tolak',
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => guard(context, () => repo.rejectRequest(l.id),
                  success: 'Pengajuan ditolak'),
            ),
            IconButton(
              tooltip: 'Setujui',
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => guard(context, () => repo.approveRequest(l.id),
                  success: 'Pengajuan disetujui'),
            ),
          ]),
        );
      },
    );
  }

  Widget _borrowed(BuildContext context) {
    final list = repo.loansByStatus(LoanStatus.borrowed);
    if (list.isEmpty) return emptyState('Tidak ada buku yang sedang dipinjam');
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final l = list[i];
        final fine = repo.previewFine(l);
        final isLate = fine > 0;
        return ListTile(
          title: Text(repo.bookById(l.bookId)?.title ?? '(buku dihapus)'),
          subtitle: Text(
            '${repo.memberById(l.memberId)?.name ?? '-'}\n'
            'Pinjam ${fmtDate(l.loanDate)} • Tempo ${fmtDate(l.dueDate)}'
            '${isLate ? '\nTerlambat • denda ${rupiah(fine)}' : ''}',
            style: TextStyle(color: isLate ? Colors.red : null),
          ),
          isThreeLine: true,
          trailing: FilledButton.tonal(
            onPressed: () => _return(context, l, fine),
            child: const Text('Kembali'),
          ),
        );
      },
    );
  }

  Future<void> _return(BuildContext context, Loan l, int fine) async {
    final msg = fine > 0
        ? 'Buku terlambat. Denda ${rupiah(fine)}. Proses pengembalian?'
        : 'Proses pengembalian buku ini?';
    if (!await confirm(context, msg)) return;
    if (!context.mounted) return;
    try {
      final r = repo.returnBook(l.id);
      toast(context, r.fine > 0
          ? 'Dikembalikan. Denda ${rupiah(r.fine)}'
          : 'Dikembalikan tepat waktu');
    } on LibraryException catch (e) {
      toast(context, e.message);
    }
  }

  Future<void> _borrowDialog(BuildContext context) async {
    String? memberId;
    String? bookId;
    await showDialog<void>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, setSt) => AlertDialog(
          title: const Text('Peminjaman Langsung'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: memberId,
              decoration: const InputDecoration(labelText: 'Anggota'),
              items: repo.members
                  .map((m) => DropdownMenuItem(
                      value: m.id, child: Text('${m.name} (${m.nis})')))
                  .toList(),
              onChanged: (v) => setSt(() => memberId = v),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: bookId,
              decoration: const InputDecoration(labelText: 'Buku'),
              items: repo.books
                  .where((b) => b.stock > 0)
                  .map((b) => DropdownMenuItem(
                      value: b.id, child: Text('${b.title} (stok ${b.stock})')))
                  .toList(),
              onChanged: (v) => setSt(() => bookId = v),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dc), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (memberId == null || bookId == null) return;
                if (guard(context, () => repo.borrowDirect(memberId!, bookId!),
                    success:
                        'Dipinjam, jatuh tempo ${LoanRules.loanDays} hari lagi')) {
                  Navigator.pop(dc);
                }
              },
              child: const Text('Proses'),
            ),
          ],
        ),
      ),
    );
  }
}
