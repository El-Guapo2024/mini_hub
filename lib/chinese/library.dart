import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// An imported book: the file, and where reading left off.
class Book {
  Book({required this.file, this.cfi});

  final File file;

  /// The epub.js CFI of the last position, or null for the beginning.
  String? cfi;

  String get title {
    final name = file.uri.pathSegments.last;
    return name.endsWith('.epub') ? name.substring(0, name.length - 5) : name;
  }
}

/// The shelf: epubs copied into the app's documents directory, plus one JSON
/// file of reading positions. Device-written, same side of the split as the
/// attempt log — content that ships with the app never lives here.
class Library {
  Library._(this._dir, this._positions);

  final Directory _dir;
  final Map<String, String> _positions; // file name -> cfi

  File get _positionsFile => File('${_dir.path}/positions.json');

  static Future<Library> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/chinese_books');
    await dir.create(recursive: true);
    var positions = <String, String>{};
    final f = File('${dir.path}/positions.json');
    if (await f.exists()) {
      try {
        positions = Map<String, String>.from(
          jsonDecode(await f.readAsString()) as Map,
        );
      } on FormatException {
        // A corrupt positions file loses bookmarks, not books.
      }
    }
    return Library._(dir, positions);
  }

  Future<List<Book>> books() async {
    final files = await _dir
        .list()
        .where((e) => e is File && e.path.endsWith('.epub'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final f in files)
        Book(file: f, cfi: _positions[f.uri.pathSegments.last]),
    ];
  }

  /// Copy an epub picked elsewhere onto the shelf.
  Future<Book> import(String sourcePath) async {
    final name = Uri.file(sourcePath).pathSegments.last;
    final dest = await File(sourcePath).copy('${_dir.path}/$name');
    return Book(file: dest);
  }

  Future<void> savePosition(Book book, String cfi) async {
    book.cfi = cfi;
    _positions[book.file.uri.pathSegments.last] = cfi;
    await _positionsFile.writeAsString(jsonEncode(_positions));
  }
}
