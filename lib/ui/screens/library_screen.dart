import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../chinese/card_store.dart';
import '../../chinese/library.dart';
import 'reader_screen.dart';

/// The shelf: pick a book, import one, or share the card deck out to Anki.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Library? _library;
  List<Book> _books = const [];
  int _cardCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final library = _library ?? await Library.open();
    final books = await library.books();
    final cards = await (await CardStore.open()).all();
    if (!mounted) return;
    setState(() {
      _library = library;
      _books = books;
      _cardCount = cards.length;
    });
  }

  Future<void> _import() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    final path = picked?.files.single.path;
    if (path == null || _library == null) return;
    await _library!.import(path);
    await _load();
  }

  Future<void> _exportCards() async {
    final store = await CardStore.open();
    final cards = await store.all();
    if (!mounted) return;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No cards yet — tap words while reading.'),
        ),
      );
      return;
    }
    final file = await store.exportTsv();
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/tab-separated-values'),
    ], subject: 'Anki deck (${cards.length} cards)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinese'),
        actions: [
          // Labelled, with the live count — an unlabelled share glyph was
          // invisible as "the Anki deck option".
          TextButton.icon(
            onPressed: _exportCards,
            icon: const Icon(Icons.ios_share, size: 18),
            label: Text('Anki ($_cardCount)'),
          ),
        ],
      ),
      body: _library == null
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const Center(child: Text('Import an EPUB to start reading.'))
          : ListView(
              children: [
                for (final book in _books)
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: Text(book.title),
                    subtitle: book.cfi == null ? null : const Text('continue'),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ReaderScreen(book: book, library: _library!),
                        ),
                      );
                      await _load();
                    },
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _import,
        tooltip: 'Import EPUB',
        child: const Icon(Icons.add),
      ),
    );
  }
}
