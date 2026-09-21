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
  const CompanionBar({
    super.key,
    required this.session,
    required this.speech,
    this.onClose,
  });

  final TutorSession session;
  final Speech speech;

  /// Puts the strip away. It carries its own way out because the reader's
  /// control row is hidden while this is open — that row held nothing but
  /// this strip's own toggle, and left an empty band under the chat.
  final VoidCallback? onClose;

  @override
  State<CompanionBar> createState() => _CompanionBarState();
}

class _CompanionBarState extends State<CompanionBar> {
  final TextEditingController _input = TextEditingController();
  final Transcriber _transcriber = Transcriber();

  bool _busy = false;
  bool _listening = false;
  String? _error;

  /// The conversation itself lives in the session; this only says whether it
  /// is on screen. Collapsing hands the page back without losing the thread,
  /// which dropping the answer used to do.
  bool _showChat = true;
  final ScrollController _scroll = ScrollController();

  /// The ceiling on how much of the screen the conversation may take. It
  /// scrolls inside that; the book keeps the rest.
  static const double _maxChatFraction = 0.35;

  /// The start still in flight, if the mic was tapped off before it finished.
  Future<String?>? _starting;

  @override
  void initState() {
    super.initState();
    // Warm the sherpa-onnx model in the background so the first tap of the
    // mic doesn't stall. It is ~160MB and ships in the bundle, so the wait
    // is copying it out on first launch, not a download.
    _transcriber.ensureReady().catchError((_) {});
  }

  @override
  void dispose() {
    _transcriber.dispose();
    _input.dispose();
    _scroll.dispose();
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
      // The answer is already in the session's transcript; this only brings
      // the conversation back into view if it had been collapsed.
      setState(() => _showChat = true);
      _scrollToEnd();
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
    // Lit at once: loading the recogniser takes a moment, and a mic that
    // does nothing meanwhile reads as broken.
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
    // Tapped off while the model was still loading: without waiting here the
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

  /// A new answer should be the one you are looking at, not something you
  /// have to scroll down to find.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  /// Questions sit quiet and small, replies read as the body text. Enough to
  /// tell speakers apart without chat bubbles, which a strip this short has
  /// no room for.
  Widget _turn(BuildContext context, TutorTurn turn) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (turn.fromUser) {
      return Text(
        turn.text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return SelectableText(
      turn.text,
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final turns = widget.session.transcript;
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
          if (_showChat && turns.isNotEmpty)
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
                  // A share of the screen rather than a fixed 160, which on
                  // any real phone left a long answer scrolling inside a
                  // window three lines tall while the page behind it had
                  // room to spare.
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.sizeOf(context).height * _maxChatFraction,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        // The whole session, not just the last reply: a
                        // question about an answer needs the answer still
                        // on screen to point at.
                        child: ListView.separated(
                          controller: _scroll,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: turns.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _turn(context, turns[i]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Hide the conversation',
                        onPressed: () {
                          widget.speech.stop();
                          setState(() => _showChat = false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            // Sitting on the screen's edge now, so the bar owes the home
            // indicator its own clearance — but only while the keyboard is
            // down, since the keyboard already covers that ground.
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.viewInsetsOf(context).bottom > 0
                  ? 10
                  : 10 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Row(
              children: [
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Close companion',
                    onPressed: widget.onClose,
                  ),
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
                      // Grows to five lines and scrolls inside itself after
                      // that, so a long question is still reviewable before
                      // sending without burying the book.
                      maxLines: 5,
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
