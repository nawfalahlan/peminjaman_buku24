import 'package:flutter/material.dart';

import '../services/library_repository.dart';

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Menjalankan [action]; bila melempar [LibraryException], tampilkan pesannya.
/// Mengembalikan true bila sukses.
bool guard(BuildContext context, VoidCallback action, {String? success}) {
  try {
    action();
    if (success != null) toast(context, success);
    return true;
  } on LibraryException catch (e) {
    toast(context, e.message);
    return false;
  }
}

Future<bool> confirm(BuildContext context, String message,
    {String okLabel = 'Ya'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(okLabel)),
      ],
    ),
  );
  return r ?? false;
}

Widget searchField(ValueChanged<String> onChanged, {String hint = 'Cari...'}) =>
    TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );

Widget emptyState(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );

String? notEmpty(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;
