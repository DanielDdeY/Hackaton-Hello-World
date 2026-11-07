import '../entities/post_failure.dart';

final class PostCancellation {
  bool _cancelled = false;
  final _listeners = <void Function()>{};

  bool get isCancelled => _cancelled;

  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final listeners = _listeners.toList();
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  void check() {
    if (_cancelled) throw const PostFailure(PostFailureReason.cancelled);
  }
}
