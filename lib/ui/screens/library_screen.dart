import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../chinese/library.dart';
import '../widgets/api_key_dialog.dart';
import 'reader_screen.dart';

/// The shelf: pick a book or import one.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Library? _library;
  List<Book> _books = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final library = _library ?? await Library.open();
    final books = await library.books();
    if (!mounted) return;
    setState(() {
      _library = library;
      _books = books;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinese'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Anthropic API key',
            onPressed: () => showApiKeyDialog(context),
          ),
        ],
      ),
      // Pull to re-read the shelf. A book can land in the documents
      // directory while this screen is open — AirDropped, copied in, put
      // there by a tool — and without this the only way to see it is to
      // leave the screen and come back, which reads as "the book is lost".
      body: _library == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _books.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Import an EPUB to start reading.')),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Already added one? Pull down to look again.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        for (final book in _books)
                          ListTile(
                            leading: const Icon(Icons.menu_book),
                            title: Text(book.title),
                            subtitle: book.cfi == null
                                ? null
                                : const Text('continue'),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReaderScreen(
                                    book: book,
                                    library: _library!,
                                  ),
                                ),
                              );
                              await _load();
                            },
                          ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _import,
        tooltip: 'Import EPUB',
        child: const Icon(Icons.add),
      ),
    );
  }
}
