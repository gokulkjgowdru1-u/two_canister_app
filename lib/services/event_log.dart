import 'package:flutter/foundation.dart';

/// Event log used by the "LIVE LOG" / "BINARY LOG" panel. Channel-based —
/// each project ("2 CANISTER" and "9 CANISTER") gets its own independent
/// log, so switching projects in the sidebar shows only that project's
/// events. Each entry carries BOTH a plain-English message (for LIVE LOG)
/// and a technical message showing exactly what data went to which port
/// (for BINARY LOG).
class LogEntry {
  final String time; // hh:mm:ss
  final String human; // plain-English, e.g. "Canister 3 fired"
  final String binary; // technical, e.g. "cmd '3' → 192.168.8.3:9000"

  LogEntry({required this.time, required this.human, required this.binary});
}

class EventLog {
  static const String channelTwoCanister = 'two_canister';
  static const String channelNineCanister = 'nine_canister';

  static const int _maxEntries = 50;

  static final Map<String, ValueNotifier<List<LogEntry>>> _channels = {};

  static ValueNotifier<List<LogEntry>> _notifierFor(String channel) {
    return _channels.putIfAbsent(channel, () => ValueNotifier<List<LogEntry>>([]));
  }

  /// Listen to this to get live updates for a specific channel.
  static ValueListenable<List<LogEntry>> entriesFor(String channel) =>
      _notifierFor(channel);

  /// [message] is the plain-English line shown in LIVE LOG.
  /// [binary] is the technical line (data/command → host:port) shown in
  /// BINARY LOG. If omitted, BINARY LOG falls back to [message].
  static void log(String message, {required String channel, String? binary}) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');

    final entry = LogEntry(
      time: '$hh:$mm:$ss',
      human: message,
      binary: binary ?? message,
    );

    final notifier = _notifierFor(channel);
    final updated = List<LogEntry>.from(notifier.value)..add(entry);
    if (updated.length > _maxEntries) {
      updated.removeRange(0, updated.length - _maxEntries);
    }
    notifier.value = updated;
  }

  /// Clears only the given channel's log (both LIVE and BINARY views).
  static void clear(String channel) {
    _notifierFor(channel).value = [];
  }
}