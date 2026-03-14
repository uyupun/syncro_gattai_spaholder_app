import '../interfaces/gesture_input.dart';

class LongPressInput implements GestureInput {
  bool _detected = false;

  @override
  void feed(double dx, double dy) {
    _detected = true;
  }

  @override
  bool get isDetected => _detected;

  @override
  void reset() {
    _detected = false;
  }
}
