# Anki's Rust core (via ~/ws/anki-sync-poc/anki/mini_hub_bridge), linked
# into the app so cards sync with AnkiWeb. The xcframework is built by
# tool/build_anki_bridge.sh and is gitignored.
Pod::Spec.new do |s|
  s.name     = 'AnkiBridge'
  s.version  = '0.0.1'
  s.summary  = "Anki's core, for adding cards and syncing with AnkiWeb."
  s.homepage = 'https://github.com/ankitects/anki'
  s.license  = { :type => 'AGPL-3.0-or-later' }
  s.author   = 'mini_hub'
  s.source   = { :path => '.' }
  s.platform = :ios, '15.6'
  s.vendored_frameworks = 'MiniHubAnkiBridge.xcframework'
  s.frameworks = 'Security', 'SystemConfiguration'
  # Nothing in Swift calls these; Dart finds them at runtime, so keep the
  # linker from stripping them.
  #
  # And keep their names in a release build: Xcode strips every symbol from
  # an app by default, and Dart looks these up by name at runtime — so the
  # simulator (debug) worked while a TestFlight build would have failed on
  # the first Anki call. Non-global keeps exported names, strips the rest.
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -Wl,-u,_anki_bridge_call -Wl,-u,_anki_bridge_free',
    'STRIP_STYLE' => 'non-global'
  }
end
