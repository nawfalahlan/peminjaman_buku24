import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/library_repository.dart';
import '../../utils/ui_helpers.dart';

/// Kelola data buku: cari, tambah, ubah, hapus.
class BooksTab extends StatefulWidget {
  final LibraryRepository repo;
  const BooksTab({super.key, required this.repo});

  @override
  State<BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<BooksTab> {
  String _query = '';

  void _openForm([Book? book]) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BookFormScreen(repo: widget.repo, book: book)),
    );
  }

  Future<void> _delete(Book b) async {
    if (await confirm(context, 'Hapus buku "${b.title}"?', okLabel: 'Hapus') &&
        mounted) {
      guard(context, () => widget.repo.deleteBook(b.id), success: 'Buku dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: widget.repo,
        builder: (context, _) {
          final list = widget.repo.searchBooks(query: _query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: searchField((v) => setState(() => _query = v),
                    hint: 'Cari judul / pengarang / penerbit'),
              ),
              Expanded(
                child: list.isEmpty
                    ? emptyState('Belum ada buku')
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final b = list[i];
                          return ListTile(
                            title: Text(b.title),
                            subtitle: Text(
                                '${b.author} • ${b.publisher}\n${b.category} • Rak ${b.shelf} • Stok ${b.stock}'),
                            isThreeLine: true,
                            onTap: () => _openForm(b),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(b),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Form tambah / ubah buku.
class BookFormScreen extends StatefulWidget {
  final LibraryRepository repo;
  final Book? book;
  const BookFormScreen({super.key, required this.repo, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.book?.title);
  late final _author = TextEditingController(text: widget.book?.author);
  late final _publisher = TextEditingController(text: widget.book?.publisher);
  late final _category = TextEditingController(text: widget.book?.category);
  late final _stock =
      TextEditingController(text: widget.book?.stock.toString() ?? '1');
  late final _shelf = TextEditingController(text: widget.book?.shelf);

  @override
  void dispose() {
    for (final c in [_title, _author, _publisher, _category, _stock, _shelf]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final b = Book(
      id: widget.book?.id ?? '',
      title: _title.text.trim(),
      author: _author.text.trim(),
      publisher: _publisher.text.trim(),
      category: _category.text.trim(),
      stock: int.parse(_stock.text.trim()),
      shelf: _shelf.text.trim(),
    );
    if (guard(context, () => widget.repo.saveBook(b))) {
      Navigator.pop(context);
    }
  }

  Widget _field(String label, TextEditingController c,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: number
            ? (v) => (int.tryParse(v ?? '') == null || int.parse(v!) < 0)
                ? 'Isi angka >= 0'
                : null
            : notEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.book == null ? 'Tambah Buku' : 'Ubah Buku')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Judul', _title),
            _field('Pengarang', _author),
            _field('Penerbit', _publisher),
            _field('Kategori', _category),
            _field('Stok', _stock, number: true),
            _field('Rak', _shelf),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
