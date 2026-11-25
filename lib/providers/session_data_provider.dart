import 'package:flutter/foundation.dart';

// A request may finish after its session and provider have been disposed.
abstract class SessionDataProvider extends ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
