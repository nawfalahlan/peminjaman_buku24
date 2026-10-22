import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraksi penyimpanan teks agar logika bisa diuji tanpa file sungguhan.
abstract class Storage {
  /// Membaca isi penyimpanan, `null` bila belum ada.
  Future<String?> read();

  /// Menimpa isi penyimpanan.
  Future<void> write(String content);
}

/// Penyimpanan ke file JSON di folder dokumen aplikasi (akses file).
class FileStorage implements Storage {
  static const _fileName = 'perpustakaan.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<String?> read() async {
    final f = await _file();
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String content) async {
    final f = await _file();
    await f.writeAsString(content, flush: true);
  }
}

/// Penyimpanan di memori, dipakai untuk unit test.
class MemoryStorage implements Storage {
  String? content;

  @override
  Future<String?> read() async => content;

  @override
  Future<void> write(String c) async => content = c;
}

/// Penyimpanan di browser (localStorage) untuk platform web.
class WebStorage implements Storage {
  static const _key = 'perpustakaan_data';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String content) async =>
      (await SharedPreferences.getInstance()).setString(_key, content);
}
