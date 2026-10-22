import 'package:flutter/material.dart';

import '../../models/member.dart';
import '../../services/library_repository.dart';
import '../../utils/ui_helpers.dart';

/// Kelola data anggota (siswa).
class MembersTab extends StatefulWidget {
  final LibraryRepository repo;
  const MembersTab({super.key, required this.repo});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  String _query = '';

  void _openForm([Member? m]) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MemberFormScreen(repo: widget.repo, member: m)),
    );
  }

  Future<void> _delete(Member m) async {
    if (await confirm(context, 'Hapus anggota "${m.name}"?', okLabel: 'Hapus') &&
        mounted) {
      guard(context, () => widget.repo.deleteMember(m.id),
          success: 'Anggota dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.person_add),
      ),
      body: ListenableBuilder(
        listenable: widget.repo,
        builder: (context, _) {
          final q = _query.trim().toLowerCase();
          final list = widget.repo.members
              .where((m) =>
                  q.isEmpty ||
                  m.name.toLowerCase().contains(q) ||
                  m.nis.contains(q) ||
                  m.className.toLowerCase().contains(q))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: searchField((v) => setState(() => _query = v),
                    hint: 'Cari nama / NIS / kelas'),
              ),
              Expanded(
                child: list.isEmpty
                    ? emptyState('Belum ada anggota')
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final m = list[i];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(m.name),
                            subtitle: Text('NIS ${m.nis} • ${m.className}'),
                            onTap: () => _openForm(m),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(m),
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

/// Form tambah / ubah anggota.
class MemberFormScreen extends StatefulWidget {
  final LibraryRepository repo;
  final Member? member;
  const MemberFormScreen({super.key, required this.repo, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nis = TextEditingController(text: widget.member?.nis);
  late final _name = TextEditingController(text: widget.member?.name);
  late final _class = TextEditingController(text: widget.member?.className);
  late final _user = TextEditingController(text: widget.member?.username);
  late final _pass = TextEditingController(text: widget.member?.password);

  @override
  void dispose() {
    for (final c in [_nis, _name, _class, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final m = Member(
      id: widget.member?.id ?? '',
      nis: _nis.text.trim(),
      name: _name.text.trim(),
      className: _class.text.trim(),
      username: _user.text.trim(),
      password: _pass.text,
    );
    if (guard(context, () => widget.repo.saveMember(m))) {
      Navigator.pop(context);
    }
  }

  Widget _field(String label, TextEditingController c, {void Function(String)? onChanged}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          onChanged: onChanged,
          decoration:
              InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: notEmpty,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.member == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Tambah Anggota' : 'Ubah Anggota')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('NIS', _nis, onChanged: (v) {
              // Anggota baru: username & password default = NIS.
              if (isNew) {
                _user.text = v;
                _pass.text = v;
              }
            }),
            _field('Nama', _name),
            _field('Kelas', _class),
            _field('Username', _user),
            _field('Password', _pass),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
