import 'package:flutter/material.dart';

import '../../chinese/speech.dart';
import '../../chinese/transcriber.dart';
import '../../chinese/tutor.dart';

/// The companion as a slim strip under the page, never a sheet over it.
///
/// Voice mode: hold the mic, speak, release — the question sends itself.
/// Talk mode: answers are read aloud (the speaker toggle turns that off).
/// The answer is a compact card above the strip; the book stays visible.
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
  bool _speakAnswers = true;
  String? _answer;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Fetch the Whisper model in the background so the first hold-to-talk
    // doesn't stall on a 140MB download.
    _transcriber.ensureReady();
  }

  @override
  void dispose() {
    _transcriber.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final a = await widget.session.ask(q);
      if (!mounted) return;
      setState(() => _answer = a);
      if (_speakAnswers) {
        // Answers are English prose with Chinese examples; the English
        // voice reads that mix far better than the Chinese one.
        await widget.speech.speak(a, language: 'en-US');
      }
    } on TutorException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startListening() async {
    // Words appear in the field while speaking — streaming Whisper.
    final ok = await _transcriber.start((partial) {
      if (mounted) setState(() => _input.text = partial);
    });
    if (ok && mounted) setState(() => _listening = true);
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    setState(() {
      _listening = false;
      _busy = true;
    });
    final text = await _transcriber.stop();
    if (!mounted) return;
    setState(() => _busy = false);
    if (text.isEmpty) return;
    _input.text = text;
    // Release sends what was heard — voice mode needs no second gesture.
    await _send();
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  // Hold to talk; release to send.
                  GestureDetector(
                    onLongPressStart: (_) => _startListening(),
                    onLongPressEnd: (_) => _stopListening(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _listening ? cs.primary : cs.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _listening ? Icons.mic : Icons.mic_none,
                        size: 22,
                        color: _listening
                            ? cs.onPrimary
                            : cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 3,
                        style: theme.textTheme.bodyMedium,
                        decoration: const InputDecoration(
                          hintText: 'Hold the mic, or type…',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      _speakAnswers ? Icons.volume_up : Icons.volume_off,
                      size: 20,
                    ),
                    color: _speakAnswers ? cs.primary : theme.disabledColor,
                    visualDensity: VisualDensity.compact,
                    tooltip: _speakAnswers
                        ? 'Answers are read aloud'
                        : 'Answers are silent',
                    onPressed: () =>
                        setState(() => _speakAnswers = !_speakAnswers),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
