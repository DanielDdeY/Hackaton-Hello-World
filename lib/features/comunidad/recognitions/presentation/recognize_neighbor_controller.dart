import 'package:flutter/foundation.dart';

import '../domain/entities/recognition.dart';
import '../domain/services/recognition_repository.dart';

final class RecognizeNeighborController extends ChangeNotifier {
  RecognizeNeighborController(this._repository);

  final RecognitionRepository _repository;
  bool _isSaving = false;
  bool _disposed = false;
  RecognitionFailureReason? _failure;

  bool get isSaving => _isSaving;
  RecognitionFailureReason? get failure => _failure;

  Future<bool> send(RecognitionDraft draft) async {
    if (_isSaving) return false;
    _isSaving = true;
    _failure = null;
    notifyListeners();
    try {
      await _repository.send(draft);
      return true;
    } on RecognitionFailure catch (error) {
      _failure = error.reason;
      return false;
    } on Exception {
      _failure = RecognitionFailureReason.unavailable;
      return false;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
