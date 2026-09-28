import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Android build's failures that only a phone shows.
///
/// Each of these passed `flutter run` and every test here, because debug
/// builds carry their own manifest and nothing in a widget test starts an
/// Activity: a release APK that crashed on launch, a companion with no
/// network, a mic that never asked, and a read-aloud voice that could not
/// find the phone's speech engine.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('the release manifest asks for the network and the mic', () {
    // Flutter's debug and profile manifests add INTERNET on their own; the
    // release one gets only what is written here.
    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.RECORD_AUDIO'));
  });

  test('the phone\'s text-to-speech engines are visible to the app', () {
    // From Android 11, without this query flutter_tts finds no voice at all.
    expect(manifest, contains('android.intent.action.TTS_SERVICE'));
  });

  test('MainActivity lives where the manifest says it does', () {
    // ".MainActivity" resolves against the namespace. When the namespace
    // moved to com.juanluera.minihub and the class stayed in
    // com.example.mini_hub, the release app crashed before its first frame.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final namespace = RegExp(
      r'namespace = "([^"]+)"',
    ).firstMatch(gradle)!.group(1)!;
    expect(manifest, contains('android:name=".MainActivity"'));

    final path =
        'android/app/src/main/kotlin/${namespace.replaceAll('.', '/')}'
        '/MainActivity.kt';
    final activity = File(path);
    expect(activity.existsSync(), isTrue, reason: '$path is missing');
    expect(activity.readAsStringSync(), contains('package $namespace\n'));
  });

  test('backups leave out the keys the Keystore sealed', () {
    // A restored key that cannot be decrypted fails the secure store on the
    // new phone instead of it starting empty.
    for (final rules in [
      'android/app/src/main/res/xml/data_extraction_rules.xml',
      'android/app/src/main/res/xml/backup_rules.xml',
    ]) {
      expect(
        File(rules).readAsStringSync(),
        contains('<exclude domain="sharedpref" path="." />'),
        reason: rules,
      );
    }
    expect(manifest, contains('@xml/data_extraction_rules'));
    expect(manifest, contains('@xml/backup_rules'));
  });
}
