/// Peran pengguna aplikasi (hak akses).
enum Role { staff, member }

/// Data anggota perpustakaan (siswa).
class Member {
  /// ID unik anggota. Kosong ("") berarti anggota baru.
  final String id;

  /// Nomor Induk Siswa.
  final String nis;
  final String name;
  final String className;

  /// Username untuk login (default: NIS).
  final String username;

  /// Catatan: untuk keperluan tugas, password disimpan apa adanya.
  /// Pada aplikasi produksi wajib di-hash.
  final String password;

  const Member({
    this.id = '',
    required this.nis,
    required this.name,
    required this.className,
    required this.username,
    required this.password,
  });

  Member copyWith({
    String? id,
    String? nis,
    String? name,
    String? className,
    String? username,
    String? password,
  }) =>
      Member(
        id: id ?? this.id,
        nis: nis ?? this.nis,
        name: name ?? this.name,
        className: className ?? this.className,
        username: username ?? this.username,
        password: password ?? this.password,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nis': nis,
        'name': name,
        'className': className,
        'username': username,
        'password': password,
      };

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        nis: j['nis'] as String,
        name: j['name'] as String,
        className: j['className'] as String,
        username: j['username'] as String,
        password: j['password'] as String,
      );
}

/// Sesi login yang sedang aktif.
class Session {
  final Role role;

  /// ID anggota (untuk [Role.member]); untuk petugas berisi "staff".
  final String userId;
  final String name;

  const Session({required this.role, required this.userId, required this.name});
}
