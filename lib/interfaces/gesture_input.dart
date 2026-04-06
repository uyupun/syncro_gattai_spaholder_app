abstract interface class GestureInput {
  void feed(double dx, double dy);
  bool get isDetected;
  void reset();
}
