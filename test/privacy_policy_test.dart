import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The privacy policy is a declaration, published from this repository to
/// both stores. It went stale once as a Gist beside the code — still saying
/// keys lived only in the iOS Keychain after the Android build existed — so
/// these pin it to what the app actually does, and pin both stores to it.
void main() {
  const path = 'docs/privacy-policy.md';
  const url = 'https://github.com/El-Guapo2024/mini_hub/blob/main/$path';
  final policy = File(path).readAsStringSync();

  test('it names every service the app can send anything to', () {
    // The three connections in docs/app-store.md's "What actually leaves
    // the phone". A fourth there needs a line here, and in the policy.
    expect(policy, contains('Anthropic'));
    expect(policy, contains('Azure Speech'));
    expect(policy, contains('AnkiWeb'));
  });

  test('it says where keys are kept on both platforms', () {
    expect(policy, contains('iOS Keychain'));
    expect(policy, contains('Android Keystore'));
  });

  test('both stores are sent this file, not another copy', () {
    for (final script in [
      'tools/ci/app_store_metadata.py',
      'docs/play-store.md',
      'docs/app-store.md',
    ]) {
      expect(File(script).readAsStringSync(), contains(url), reason: script);
    }
  });
}
