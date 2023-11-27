import 'dart:async';

LoadingIndicatorService loadingService = LoadingIndicatorService();

class LoadingIndicatorService {
  final StreamController<int> _isLoadingStream = StreamController<int>();
  late Stream<int> loadingCount;

  int _count = 0;
  int localMax = 0;

  LoadingIndicatorService() {
    loadingCount = _isLoadingStream.stream.asBroadcastStream();
  }

  /// Automatically track a future
  void addFuture(Future<dynamic> trackedFuture) {
    _increment();
    //When this future is complete success or failure.
    trackedFuture.whenComplete(() => _decrement());
  }

  void _increment() {
    _count++;
    if (_count > localMax) {
      localMax = _count;
    }
    _isLoadingStream.add(_count);
  }

  void _decrement() {
    _count--;
    if (_count == 0) {
      //Reset max when count is 0
      localMax = 0;
    }
    _isLoadingStream.add(_count);
  }
}
