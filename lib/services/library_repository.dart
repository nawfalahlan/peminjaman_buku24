import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/loan.dart';
import '../models/member.dart';
import 'storage.dart';

/// Kesalahan aturan bisnis (pesan siap ditampilkan ke pengguna).
class LibraryException implements Exception {
  final String message;
  LibraryException(this.message);

  @override
  String toString() => message;
}

/// Aturan peminjaman.
class LoanRules {
  /// Lama peminjaman (hari).
  static const int loanDays = 7;

  /// Denda per hari keterlambatan (Rupiah).
  static const int finePerDay = 1000;

  /// Batas buku aktif (diajukan + dipinjam) per anggota.
  static const int maxActiveLoans = 3;

  /// Pengingat muncul bila sisa hari <= nilai ini.
  static const int reminderDays = 2;
}

/// Perhitungan tanggal & denda (fungsi murni agar mudah diuji).
class FineCalculator {
  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Jumlah hari terlambat; 0 bila tepat waktu / lebih awal.
  static int lateDays(DateTime dueDate, DateTime returnDate) {
    final diff = _dateOnly(returnDate).difference(_dateOnly(dueDate)).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Denda = hari terlambat x [perDay].
  static int fine(DateTime dueDate, DateTime returnDate,
          {int perDay = LoanRules.finePerDay}) =>
      lateDays(dueDate, returnDate) * perDay;

  /// Sisa hari menuju [dueDate] dari [now] (negatif bila lewat).
  static int daysLeft(DateTime dueDate, DateTime now) =>
      _dateOnly(dueDate).difference(_dateOnly(now)).inDays;
}

/// Buku beserta jumlah peminjamannya (untuk laporan buku terfavorit).
class TopBook {
  final Book book;
  final int count;
  const TopBook(this.book, this.count);
}

/// Hasil rekapitulasi peminjaman pada suatu periode.
class Recap {
  final int totalLoans;
  final int returned;
  final int stillBorrowed;
  final int totalFine;
  final List<TopBook> topBooks;
  const Recap({
    required this.totalLoans,
    required this.returned,
    required this.stillBorrowed,
    required this.totalFine,
    required this.topBooks,
  });
}

/// Pusat data & logika aplikasi: buku, anggota, sirkulasi, laporan, login.
class LibraryRepository extends ChangeNotifier {
  LibraryRepository(this._storage, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const staffUsername = 'admin';
  static const staffPassword = 'admin123';

  final Storage _storage;
  final DateTime Function() _clock;

  final List<Book> _books = [];
  final List<Member> _members = [];
  final List<Loan> _loans = [];
  int _nextId = 1;

  Session? session;

  List<Book> get books => List.unmodifiable(_books);
  List<Member> get members => List.unmodifiable(_members);
  List<Loan> get loans => List.unmodifiable(_loans);
  DateTime get now => _clock();

  // ---------------------------------------------------------------- load/save

  /// Memuat data dari penyimpanan; bila kosong, isi data contoh.
  Future<void> init() async {
    final raw = await _storage.read();
    if (raw == null || raw.trim().isEmpty) {
      _seed();
      await _persist();
    } else {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _nextId = j['nextId'] as int;
      _books.addAll((j['books'] as List)
          .map((e) => Book.fromJson(e as Map<String, dynamic>)));
      _members.addAll((j['members'] as List)
          .map((e) => Member.fromJson(e as Map<String, dynamic>)));
      _loans.addAll((j['loans'] as List)
          .map((e) => Loan.fromJson(e as Map<String, dynamic>)));
    }
    notifyListeners();
  }

  Future<void> _persist() => _storage.write(jsonEncode({
        'nextId': _nextId,
        'books': _books.map((e) => e.toJson()).toList(),
        'members': _members.map((e) => e.toJson()).toList(),
        'loans': _loans.map((e) => e.toJson()).toList(),
      }));

  void _commit() {
    unawaited(_persist());
    notifyListeners();
  }

  String _newId(String prefix) => '$prefix${_nextId++}';

  void _seed() {
    const data = [
      ['Laskar Pelangi', 'Andrea Hirata', 'Bentang Pustaka', 'Novel', 5, 'A-01'],
      ['Bumi Manusia', 'Pramoedya Ananta Toer', 'Hasta Mitra', 'Novel', 3, 'A-02'],
      ['Matematika Kelas X', 'Kemendikbud', 'Kemendikbud', 'Pelajaran', 10, 'B-01'],
      ['Dasar Pemrograman Dart', 'Tim RPL', 'Informatika', 'Teknologi', 4, 'C-01'],
      ['Sejarah Indonesia', 'Kemendikbud', 'Kemendikbud', 'Pelajaran', 6, 'B-02'],
      ['Filosofi Teras', 'Henry Manampiring', 'Kompas', 'Pengembangan Diri', 2, 'D-01'],
    ];
    for (final r in data) {
      _books.add(Book(
        id: _newId('B'),
        title: r[0] as String,
        author: r[1] as String,
        publisher: r[2] as String,
        category: r[3] as String,
        stock: r[4] as int,
        shelf: r[5] as String,
      ));
    }
    _members.addAll([
      Member(
          id: _newId('M'),
          nis: '1001',
          name: 'Budi Santoso',
          className: 'XI RPL 1',
          username: '1001',
          password: '1001'),
      Member(
          id: _newId('M'),
          nis: '1002',
          name: 'Siti Aminah',
          className: 'XI RPL 2',
          username: '1002',
          password: '1002'),
    ]);
  }

  // -------------------------------------------------------------------- login

  /// Login petugas / anggota. Mengembalikan false bila gagal.
  bool login(String username, String password) {
    final u = username.trim();
    if (u == staffUsername && password == staffPassword) {
      session = const Session(role: Role.staff, userId: 'staff', name: 'Petugas');
    } else {
      final m = _members.where((e) => e.username == u && e.password == password);
      if (m.isEmpty) return false;
      session = Session(
          role: Role.member, userId: m.first.id, name: m.first.name);
    }
    notifyListeners();
    return true;
  }

  void logout() {
    session = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------- books

  Book? bookById(String id) {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<String> get categories =>
      (_books.map((b) => b.category).toSet().toList()..sort());

  /// Pencarian katalog (judul/pengarang/penerbit) + filter kategori/ketersediaan.
  List<Book> searchBooks(
      {String query = '', String? category, bool onlyAvailable = false}) {
    final q = query.trim().toLowerCase();
    return _books.where((b) {
      if (category != null && b.category != category) return false;
      if (onlyAvailable && b.stock <= 0) return false;
      if (q.isEmpty) return true;
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.publisher.toLowerCase().contains(q);
    }).toList();
  }

  /// Tambah (id kosong) atau ubah buku.
  void saveBook(Book b) {
    if (b.title.trim().isEmpty) throw LibraryException('Judul wajib diisi');
    if (b.stock < 0) throw LibraryException('Stok tidak boleh negatif');
    if (b.id.isEmpty) {
      _books.add(b.copyWith(id: _newId('B')));
    } else {
      final i = _books.indexWhere((e) => e.id == b.id);
      if (i < 0) throw LibraryException('Buku tidak ditemukan');
      _books[i] = b;
    }
    _commit();
  }

  void deleteBook(String id) {
    if (_loans.any((l) => l.bookId == id && l.isActive)) {
      throw LibraryException('Buku masih dipinjam / diajukan, tidak bisa dihapus');
    }
    _books.removeWhere((b) => b.id == id);
    _commit();
  }

  // ------------------------------------------------------------------ members

  Member? memberById(String id) {
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Tambah (id kosong) atau ubah anggota; NIS & username harus unik.
  void saveMember(Member m) {
    if (m.name.trim().isEmpty || m.nis.trim().isEmpty) {
      throw LibraryException('NIS dan nama wajib diisi');
    }
    if (m.username.trim().isEmpty || m.password.isEmpty) {
      throw LibraryException('Username dan password wajib diisi');
    }
    final dup = _members.any((e) =>
        e.id != m.id && (e.nis == m.nis || e.username == m.username));
    if (dup || m.username == staffUsername) {
      throw LibraryException('NIS atau username sudah dipakai');
    }
    if (m.id.isEmpty) {
      _members.add(m.copyWith(id: _newId('M')));
    } else {
      final i = _members.indexWhere((e) => e.id == m.id);
      if (i < 0) throw LibraryException('Anggota tidak ditemukan');
      _members[i] = m;
    }
    _commit();
  }

  void deleteMember(String id) {
    if (_loans.any((l) => l.memberId == id && l.isActive)) {
      throw LibraryException('Anggota masih memiliki pinjaman aktif');
    }
    _members.removeWhere((m) => m.id == id);
    _commit();
  }

  // ----------------------------------------------------------------- sirkulasi

  Loan? _loanById(String id) {
    for (final l in _loans) {
      if (l.id == id) return l;
    }
    return null;
  }

  void _replaceLoan(Loan l) {
    final i = _loans.indexWhere((e) => e.id == l.id);
    _loans[i] = l;
  }

  List<Loan> loansByStatus(LoanStatus s) =>
      _loans.where((l) => l.status == s).toList().reversed.toList();

  /// Semua transaksi milik anggota (terbaru di atas).
  List<Loan> loansOfMember(String memberId) =>
      _loans.where((l) => l.memberId == memberId).toList().reversed.toList();

  void _validateNewLoan(String memberId, String bookId) {
    final book = bookById(bookId);
    if (book == null || memberById(memberId) == null) {
      throw LibraryException('Data buku / anggota tidak valid');
    }
    final active = _loans.where((l) => l.memberId == memberId && l.isActive);
    if (active.any((l) => l.bookId == bookId)) {
      throw LibraryException('Buku ini sudah dipinjam / diajukan anggota tersebut');
    }
    if (active.length >= LoanRules.maxActiveLoans) {
      throw LibraryException(
          'Maksimal ${LoanRules.maxActiveLoans} buku aktif per anggota');
    }
  }

  /// Anggota mengajukan peminjaman (stok belum berkurang sampai disetujui).
  Loan requestLoan(String memberId, String bookId) {
    _validateNewLoan(memberId, bookId);
    if (bookById(bookId)!.stock <= 0) throw LibraryException('Stok buku habis');
    final loan = Loan(
      id: _newId('L'),
      bookId: bookId,
      memberId: memberId,
      status: LoanStatus.requested,
      requestDate: now,
    );
    _loans.add(loan);
    _commit();
    return loan;
  }

  /// Anggota membatalkan pengajuannya.
  void cancelRequest(String loanId) => rejectRequest(loanId);

  /// Petugas menolak pengajuan.
  void rejectRequest(String loanId) {
    final l = _loanById(loanId);
    if (l == null || l.status != LoanStatus.requested) {
      throw LibraryException('Pengajuan tidak valid');
    }
    _replaceLoan(l.copyWith(status: LoanStatus.rejected));
    _commit();
  }

  void _lend(Loan l) {
    final book = bookById(l.bookId)!;
    if (book.stock <= 0) throw LibraryException('Stok buku habis');
    final t = now;
    _books[_books.indexWhere((b) => b.id == book.id)] =
        book.copyWith(stock: book.stock - 1);
    _replaceLoan(l.copyWith(
      status: LoanStatus.borrowed,
      loanDate: t,
      dueDate: t.add(const Duration(days: LoanRules.loanDays)),
    ));
  }

  /// Petugas menyetujui pengajuan: stok berkurang, jatuh tempo ditetapkan.
  void approveRequest(String loanId) {
    final l = _loanById(loanId);
    if (l == null || l.status != LoanStatus.requested) {
      throw LibraryException('Pengajuan tidak valid');
    }
    _lend(l);
    _commit();
  }

  /// Petugas memproses peminjaman langsung di meja sirkulasi.
  void borrowDirect(String memberId, String bookId) {
    _validateNewLoan(memberId, bookId);
    final l = Loan(
      id: _newId('L'),
      bookId: bookId,
      memberId: memberId,
      status: LoanStatus.requested,
      requestDate: now,
    );
    _loans.add(l);
    try {
      _lend(l);
    } catch (_) {
      _loans.removeLast();
      rethrow;
    }
    _commit();
  }

  /// Denda yang akan dikenakan bila buku dikembalikan sekarang.
  int previewFine(Loan l) =>
      l.dueDate == null ? 0 : FineCalculator.fine(l.dueDate!, now);

  /// Proses pengembalian: stok bertambah, denda dihitung otomatis.
  /// Mengembalikan transaksi yang sudah diperbarui.
  Loan returnBook(String loanId) {
    final l = _loanById(loanId);
    if (l == null || l.status != LoanStatus.borrowed) {
      throw LibraryException('Transaksi tidak valid');
    }
    final t = now;
    final updated = l.copyWith(
      status: LoanStatus.returned,
      returnDate: t,
      fine: FineCalculator.fine(l.dueDate!, t),
    );
    _replaceLoan(updated);
    final i = _books.indexWhere((b) => b.id == l.bookId);
    if (i >= 0) _books[i] = _books[i].copyWith(stock: _books[i].stock + 1);
    _commit();
    return updated;
  }

  // ------------------------------------------------------------------ laporan

  /// Pinjaman anggota yang jatuh tempo <= [LoanRules.reminderDays] hari
  /// atau sudah lewat (untuk pengingat).
  List<Loan> remindersFor(String memberId) => _loans
      .where((l) =>
          l.memberId == memberId &&
          l.status == LoanStatus.borrowed &&
          FineCalculator.daysLeft(l.dueDate!, now) <= LoanRules.reminderDays)
      .toList();

  /// Rekap peminjaman (berdasarkan tanggal pinjam) pada [from]..[to] inklusif.
  Recap recap(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    final inRange = _loans.where((l) =>
        l.loanDate != null &&
        !l.loanDate!.isBefore(start) &&
        l.loanDate!.isBefore(end));

    final counts = <String, int>{};
    var returned = 0, borrowed = 0, fine = 0, total = 0;
    for (final l in inRange) {
      total++;
      counts[l.bookId] = (counts[l.bookId] ?? 0) + 1;
      if (l.status == LoanStatus.returned) returned++;
      if (l.status == LoanStatus.borrowed) borrowed++;
      fine += l.fine;
    }
    final top = <TopBook>[];
    counts.forEach((id, c) {
      final b = bookById(id);
      if (b != null) top.add(TopBook(b, c));
    });
    top.sort((a, b) => b.count.compareTo(a.count));
    return Recap(
      totalLoans: total,
      returned: returned,
      stillBorrowed: borrowed,
      totalFine: fine,
      topBooks: top.take(5).toList(),
    );
  }
}
