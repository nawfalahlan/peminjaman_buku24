import 'package:flutter/material.dart';

import '../../services/library_repository.dart';
import '../../utils/format.dart';

/// Laporan rekapitulasi peminjaman dan buku terfavorit.
class ReportTab extends StatefulWidget {
  final LibraryRepository repo;
  const ReportTab({super.key, required this.repo});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  late DateTimeRange _range = DateTimeRange(
    start: widget.repo.now.subtract(const Duration(days: 30)),
    end: widget.repo.now,
  );

  Future<void> _pick() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Icon(icon),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label, textAlign: TextAlign.center),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final rc = widget.repo.recap(_range.start, _range.end);
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.date_range),
              label: Text(
                  'Periode: ${fmtDate(_range.start)} - ${fmtDate(_range.end)}'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              _stat('Total Pinjam', '${rc.totalLoans}', Icons.menu_book),
              _stat('Dikembalikan', '${rc.returned}', Icons.assignment_turned_in),
            ]),
            Row(children: [
              _stat('Masih Dipinjam', '${rc.stillBorrowed}', Icons.hourglass_bottom),
              _stat('Total Denda', rupiah(rc.totalFine), Icons.payments),
            ]),
            const SizedBox(height: 8),
            Text('Buku Terfavorit',
                style: Theme.of(context).textTheme.titleMedium),
            if (rc.topBooks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada data pada periode ini'),
              ),
            for (var i = 0; i < rc.topBooks.length; i++)
              ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(rc.topBooks[i].book.title),
                subtitle: Text(rc.topBooks[i].book.author),
                trailing: Text('${rc.topBooks[i].count}x'),
              ),
          ],
        );
      },
    );
  }
}
