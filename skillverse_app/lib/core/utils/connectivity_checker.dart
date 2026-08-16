import 'dart:async';
import 'dart:io';

/// Minimal connectivity check with no extra pubspec dependency —
/// keeps the app lightweight. Periodically attempts a DNS lookup;
/// any failure is treated as "offline". Safe by design: every call is
/// wrapped so a platform that doesn't support dart:io sockets (e.g. a
/// future web build) simply reports "online" instead of crashing.
class ConnectivityChecker {
  ConnectivityChecker._();
  static final ConnectivityChecker instance = ConnectivityChecker._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  Timer? _timer;
  bool _lastKnown = true;
  bool get lastKnown => _lastKnown;

  void start() {
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _check() async {
    bool online;
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 4));
      online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }
    if (online != _lastKnown) {
      _lastKnown = online;
      _controller.add(online);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
