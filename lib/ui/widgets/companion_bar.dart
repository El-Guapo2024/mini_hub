import 'package:flutter/material.dart';

import '../../chinese/speech.dart';
import '../../chinese/transcriber.dart';
import '../../chinese/tutor.dart';

/// The companion as a slim strip under the page, never a sheet over it.
///
/// Voice works like Claude Code's: tap the mic inside the field, speak in
/// English, Chinese or both, tap again — the words land in the field to
/// check, and send sends them. Answers are always spoken, each language in
/// its own voice. The answer is a compact card above the strip; the book
/// stays visible.
class CompanionBar extends StatefulWidget {
  const CompanionBar({super.key, required this.session, required this.speech});

  final TutorSession session;
  final Speech speech;

  @override
  State<CompanionBar> createState() => _CompanionBarState();
}

class _CompanionBarState extends State<CompanionBar> {
  final TextEditingController _input = TextEditingController();
  final Transcriber _transcriber = Transcriber();

  bool _busy = false;
  bool _listening = false;
  String? _answer;
  String? _error;

  /// The start still in flight, if the mic was tapped off before it finished.
  Future<String?>? _starting;

  @override
  void initState() {
    super.initState();
    // Fetch the Whisper model in the background so the first tap of the
    // mic doesn't stall on a 140MB download.
    _transcriber.ensureReady().catchError((_) {});
  }

  @override
  void dispose() {
    _transcriber.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _busy || _listening) return;
    _input.clear();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final a = await widget.session.ask(q);
      if (!mounted) return;
      setState(() => _answer = a);
      await widget.speech.speakMixed(a);
    } on TutorException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startListening() async {
    // Lit at once: loading Whisper takes a moment, and a mic that does
    // nothing meanwhile reads as broken.
    setState(() {
      _listening = true;
      _error = null;
    });
    // Awaited: the voice releasing the audio session while the recorder is
    // claiming it left the recorder with a dead session and silent input.
    await widget.speech.stop();
    _starting = _transcriber.start((partial) {
      if (mounted) setState(() => _input.text = partial);
    });
    final error = await _starting;
    _starting = null;
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _listening = false;
        _error = error;
      });
    }
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    setState(() {
      _listening = false;
      _busy = true;
    });
    // Tapped off while Whisper was still loading: without waiting here the
    // stop was dropped and the mic then recorded forever.
    final pending = _starting;
    if (pending != null && await pending != null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final text = await _transcriber.stop();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (text.isNotEmpty) _input.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_busy)
            const ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ),
          if (_answer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _answer!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Dismiss answer',
                        onPressed: () {
                          widget.speech.stop();
                          setState(() => _answer = null);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.only(left: 16),
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 3,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: _listening
                            ? 'Listening…'
                            : 'Ask, or tap the mic',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        // The mic lives inside the field: tap to talk, tap
                        // again to stop; the words stay here to check.
                        suffixIcon: IconButton(
                          icon: Icon(
                            _listening ? Icons.stop_circle : Icons.mic_none,
                            color: _listening ? cs.error : cs.onSurfaceVariant,
                          ),
                          tooltip: _listening ? 'Stop listening' : 'Speak',
                          onPressed: _listening
                              ? _stopListening
                              : _startListening,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy || _listening ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
