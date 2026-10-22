/// Data buku koleksi perpustakaan.
class Book {
  /// ID unik buku. Kosong ("") berarti buku baru yang belum disimpan.
  final String id;
  final String title;
  final String author;
  final String publisher;
  final String category;

  /// Jumlah eksemplar yang tersedia (belum dipinjam).
  final int stock;

  /// Lokasi rak penyimpanan, mis. "A-01".
  final String shelf;

  const Book({
    this.id = '',
    required this.title,
    required this.author,
    required this.publisher,
    required this.category,
    required this.stock,
    required this.shelf,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? publisher,
    String? category,
    int? stock,
    String? shelf,
  }) =>
      Book(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        publisher: publisher ?? this.publisher,
        category: category ?? this.category,
        stock: stock ?? this.stock,
        shelf: shelf ?? this.shelf,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'publisher': publisher,
        'category': category,
        'stock': stock,
        'shelf': shelf,
      };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as String,
        title: j['title'] as String,
        author: j['author'] as String,
        publisher: j['publisher'] as String,
        category: j['category'] as String,
        stock: j['stock'] as int,
        shelf: j['shelf'] as String,
      );
}
