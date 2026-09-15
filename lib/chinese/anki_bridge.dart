import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

/// Something Anki's core refused or couldn't reach, in its own words.
class AnkiException implements Exception {
  AnkiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Anki's own Rust core, linked into the app (see
/// ~/ws/anki-sync-poc/anki/mini_hub_bridge): the same code desktop Anki
/// syncs with, so a card added here reaches AnkiWeb exactly as if Anki had
/// added it. Methods and their arguments are listed in that crate's lib.rs.
class AnkiBridge {
  /// Runs [method] off the UI isolate — sync and download are network
  /// calls, and even an add touches SQLite.
  static Future<Map<String, dynamic>> call(
    String method,
    Map<String, Object?> args,
  ) {
    final encoded = jsonEncode(args);
    return Isolate.run(() => _callBlocking(method, encoded));
  }

  static Map<String, dynamic> _callBlocking(String method, String args) {
    // Statically linked into the app binary, so its symbols are in-process.
    final lib = DynamicLibrary.process();
    final call = lib
        .lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)
        >('anki_bridge_call');
    final free = lib
        .lookupFunction<
          Void Function(Pointer<Utf8>),
          void Function(Pointer<Utf8>)
        >('anki_bridge_free');
    final nativeMethod = method.toNativeUtf8();
    final nativeArgs = args.toNativeUtf8();
    try {
      final out = call(nativeMethod, nativeArgs);
      final text = out.toDartString();
      free(out);
      final reply = jsonDecode(text) as Map<String, dynamic>;
      final error = reply['error'];
      if (error != null) throw AnkiException(error as String);
      return (reply['ok'] as Map).cast<String, dynamic>();
    } finally {
      malloc.free(nativeMethod);
      malloc.free(nativeArgs);
    }
  }
}
