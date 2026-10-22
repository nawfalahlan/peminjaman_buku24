import 'package:flutter_test/flutter_test.dart';
import 'package:perpustakaan_app/models/book.dart';
import 'package:perpustakaan_app/models/loan.dart';
import 'package:perpustakaan_app/services/library_repository.dart';
import 'package:perpustakaan_app/services/storage.dart';

void main() {
  group('FineCalculator', () {
    final due = DateTime(2026, 10, 10, 9);

    test('tepat waktu -> denda 0', () {
      expect(FineCalculator.fine(due, DateTime(2026, 10, 10, 23)), 0);
    });
    test('lebih awal -> denda 0', () {
      expect(FineCalculator.fine(due, DateTime(2026, 10, 5)), 0);
    });
    test('terlambat 3 hari -> Rp 3.000', () {
      expect(FineCalculator.lateDays(due, DateTime(2026, 10, 13, 1)), 3);
      expect(FineCalculator.fine(due, DateTime(2026, 10, 13, 1)), 3000);
    });
    test('daysLeft negatif bila lewat', () {
      expect(FineCalculator.daysLeft(due, DateTime(2026, 10, 12)), -2);
    });
  });

  group('LibraryRepository', () {
    late DateTime clock;
    late LibraryRepository repo;
    late String memberId;
    late String bookId;

    setUp(() async {
      clock = DateTime(2026, 10, 1, 8);
      repo = LibraryRepository(MemoryStorage(), clock: () => clock);
      await repo.init();
      memberId = repo.members.first.id;
      bookId = repo.books.first.id;
    });

    test('login petugas & anggota, gagal bila salah', () {
      expect(repo.login('admin', 'salah'), isFalse);
      expect(repo.login('admin', 'admin123'), isTrue);
      expect(repo.login('1001', '1001'), isTrue);
    });

    test('alur pengajuan -> disetujui -> kembali terlambat', () {
      final stock0 = repo.bookById(bookId)!.stock;
      final loan = repo.requestLoan(memberId, bookId);
      expect(repo.bookById(bookId)!.stock, stock0); // belum berkurang

      repo.approveRequest(loan.id);
      expect(repo.bookById(bookId)!.stock, stock0 - 1);

      clock = DateTime(2026, 10, 1, 8).add(const Duration(days: 10));
      final r = repo.returnBook(loan.id);
      expect(r.status, LoanStatus.returned);
      expect(r.fine, 3 * LoanRules.finePerDay); // 7 hari + 3 terlambat
      expect(repo.bookById(bookId)!.stock, stock0);
    });

    test('tidak boleh pinjam buku yang sama dua kali', () {
      repo.requestLoan(memberId, bookId);
      expect(() => repo.requestLoan(memberId, bookId),
          throwsA(isA<LibraryException>()));
    });

    test('batas maksimal buku aktif', () {
      final ids = repo.books.take(LoanRules.maxActiveLoans + 1).toList();
      for (var i = 0; i < LoanRules.maxActiveLoans; i++) {
        repo.requestLoan(memberId, ids[i].id);
      }
      expect(() => repo.requestLoan(memberId, ids.last.id),
          throwsA(isA<LibraryException>()));
    });

    test('stok habis tidak bisa diajukan', () {
      repo.saveBook(repo.bookById(bookId)!.copyWith(stock: 0));
      expect(() => repo.requestLoan(memberId, bookId),
          throwsA(isA<LibraryException>()));
    });

    test('pencarian & filter katalog', () {
      expect(repo.searchBooks(query: 'laskar').length, 1);
      expect(repo.searchBooks(category: 'Pelajaran').length, 2);
      expect(repo.searchBooks(query: 'xyz'), isEmpty);
    });

    test('buku yang dipinjam tidak bisa dihapus', () {
      repo.borrowDirect(memberId, bookId);
      expect(() => repo.deleteBook(bookId), throwsA(isA<LibraryException>()));
    });

    test('pengingat muncul mendekati jatuh tempo', () {
      repo.borrowDirect(memberId, bookId);
      expect(repo.remindersFor(memberId), isEmpty);
      clock = clock.add(const Duration(days: 5)); // sisa 2 hari
      expect(repo.remindersFor(memberId).length, 1);
    });

    test('laporan: rekap & buku terfavorit', () {
      final m2 = repo.members.last.id;
      repo.borrowDirect(memberId, bookId);
      repo.borrowDirect(m2, bookId);
      repo.borrowDirect(m2, repo.books[1].id);
      final loan = repo.loansByStatus(LoanStatus.borrowed).last;
      repo.returnBook(loan.id);

      final rc = repo.recap(DateTime(2026, 10, 1), DateTime(2026, 10, 31));
      expect(rc.totalLoans, 3);
      expect(rc.returned, 1);
      expect(rc.stillBorrowed, 2);
      expect(rc.topBooks.first.book.id, bookId);
      expect(rc.topBooks.first.count, 2);
    });

    test('data tersimpan & dimuat kembali dari storage', () async {
      final st = MemoryStorage();
      final a = LibraryRepository(st);
      await a.init();
      a.saveBook(const Book(
          title: 'Buku Baru',
          author: 'A',
          publisher: 'P',
          category: 'Umum',
          stock: 1,
          shelf: 'Z-1'));
      await Future<void>.delayed(Duration.zero);
      final b = LibraryRepository(st);
      await b.init();
      expect(b.books.any((x) => x.title == 'Buku Baru'), isTrue);
    });
  });
}
