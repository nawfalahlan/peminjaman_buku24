/// Status siklus hidup sebuah transaksi peminjaman.
enum LoanStatus {
  /// Diajukan anggota, menunggu persetujuan petugas.
  requested,

  /// Sedang dipinjam.
  borrowed,

  /// Sudah dikembalikan.
  returned,

  /// Pengajuan ditolak / dibatalkan.
  rejected,
}

/// Transaksi peminjaman satu buku oleh satu anggota.
class Loan {
  final String id;
  final String bookId;
  final String memberId;
  final LoanStatus status;

  /// Waktu pengajuan oleh anggota (atau waktu pinjam langsung oleh petugas).
  final DateTime requestDate;
  final DateTime? loanDate;
  final DateTime? dueDate;
  final DateTime? returnDate;

  /// Denda (Rupiah) yang dihitung saat buku dikembalikan.
  final int fine;

  const Loan({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.status,
    required this.requestDate,
    this.loanDate,
    this.dueDate,
    this.returnDate,
    this.fine = 0,
  });

  /// True bila transaksi masih berjalan (diajukan / dipinjam).
  bool get isActive =>
      status == LoanStatus.requested || status == LoanStatus.borrowed;

  Loan copyWith({
    LoanStatus? status,
    DateTime? loanDate,
    DateTime? dueDate,
    DateTime? returnDate,
    int? fine,
  }) =>
      Loan(
        id: id,
        bookId: bookId,
        memberId: memberId,
        status: status ?? this.status,
        requestDate: requestDate,
        loanDate: loanDate ?? this.loanDate,
        dueDate: dueDate ?? this.dueDate,
        returnDate: returnDate ?? this.returnDate,
        fine: fine ?? this.fine,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'memberId': memberId,
        'status': status.name,
        'requestDate': requestDate.toIso8601String(),
        'loanDate': loanDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'fine': fine,
      };

  factory Loan.fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) =>
        j[k] == null ? null : DateTime.parse(j[k] as String);
    return Loan(
      id: j['id'] as String,
      bookId: j['bookId'] as String,
      memberId: j['memberId'] as String,
      status: LoanStatus.values.byName(j['status'] as String),
      requestDate: DateTime.parse(j['requestDate'] as String),
      loanDate: d('loanDate'),
      dueDate: d('dueDate'),
      returnDate: d('returnDate'),
      fine: (j['fine'] as int?) ?? 0,
    );
  }
}
