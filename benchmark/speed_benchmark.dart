import 'dart:async';
import 'package:core_bus/event_bus.dart';

const int iterations = 1000000;
const int listenerCount = 5;

void main() async {
  final bus = EventBus();
  const event = Event<int>.broadcast(name: 'benchmark');

  print(
    'Starting benchmark with $iterations iterations and $listenerCount listeners...',
  );

  // --- Benchmark Callback API ---
  final stopwatchCallback = Stopwatch()..start();
  int callbackCount = 0;

  final callbacks = <void Function(int)>[];
  for (int i = 0; i < listenerCount; i++) {
    void listener(int data) {
      callbackCount++;
    }

    callbacks.add(listener);
    event.addListener(bus, listener);
  }

  for (int i = 0; i < iterations; i++) {
    event.post(bus, i);
  }

  stopwatchCallback.stop();
  for (final c in callbacks) {
    event.removeListener(bus, c);
  }

  print('Callback API:');
  print('  Time: ${stopwatchCallback.elapsedMilliseconds}ms');
  print(
    '  Average: ${(stopwatchCallback.elapsedMicroseconds / iterations).toStringAsFixed(3)}μs per post',
  );
  print('  Total events delivered: $callbackCount');

  // --- Benchmark Stream API (Sync) ---
  // Using sync: true because callbacks are naturally sync,
  // and we want a fair comparison of distribution overhead.
  final stopwatchStream = Stopwatch()..start();
  int streamCount = 0;

  final subs = <StreamSubscription>[];
  for (int i = 0; i < listenerCount; i++) {
    subs.add(
      event.on(bus, sync: true).listen((data) {
        streamCount++;
      }),
    );
  }

  for (int i = 0; i < iterations; i++) {
    event.post(bus, i);
  }

  stopwatchStream.stop();
  for (final s in subs) {
    await s.cancel();
  }

  print('Stream API (Sync):');
  print('  Time: ${stopwatchStream.elapsedMilliseconds}ms');
  print(
    '  Average: ${(stopwatchStream.elapsedMicroseconds / iterations).toStringAsFixed(3)}μs per post',
  );
  print('  Total events delivered: $streamCount');

  // --- Comparison ---
  final ratio =
      stopwatchStream.elapsedMicroseconds /
      stopwatchCallback.elapsedMicroseconds;
  print('Comparison:');
  print(
    '  Callback API is ${ratio.toStringAsFixed(2)}x faster than Stream API.',
  );

  await bus.reset();
}
