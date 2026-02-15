import 'package:test/test.dart';
import 'package:core_bus/event_bus.dart';

void main() {
  group('Concurrent Modification Handling', () {
    late EventBus bus;

    setUp(() {
      bus = EventBus();
    });

    test(
      'Broadcast: listener can safely remove itself during notification',
      () {
        final event = Event<String>.broadcast(name: 'test');
        int callCount = 0;
        void listener(String data) {
          callCount++;
          event.removeListener(bus, listener);
        }

        event.addListener(bus, listener);

        event.post(bus, 'first');
        expect(callCount, 1);
        expect(bus.hasListenerFor(event), isFalse);

        event.post(bus, 'second');
        expect(callCount, 1);
      },
    );

    test(
      'Single Replay: listener can safely remove itself during notification',
      () {
        final event = Event<String>.replay(name: 'test');
        int callCount = 0;
        void listener(String data) {
          callCount++;
          event.removeListener(bus, listener);
        }

        event.addListener(bus, listener);

        event.post(bus, 'first');
        expect(callCount, 1);
        expect(bus.hasListenerFor(event), isFalse);

        event.post(bus, 'second');
        expect(callCount, 1);
      },
    );

    test(
      'Multiple Replays: listener can safely remove another during notification',
      () {
        final event = Event<int>.replays(name: 'test', limit: 5);
        int countA = 0;
        int countB = 0;

        void listenerB(int data) {
          countB++;
        }

        void listenerA(int data) {
          countA++;
          event.removeListener(bus, listenerB);
        }

        event.addListener(bus, listenerA);
        event.addListener(bus, listenerB);

        event.post(bus, 1);
        event.post(bus, 2);

        expect(countA, 2);
        // Both are called because removal is deferred until after the loop
        expect(countB, 1);
        expect(bus.listenerCountFor(event), 1); // B is now removed
      },
    );

    test('Handles nested posts correctly', () {
      final event = Event<String>.broadcast(name: 'test');
      int count = 0;
      final heard = <String>[];
      void listener(String data) {
        count++;
        heard.add(data);
        if (data == 'outer') {
          event.post(bus, 'inner');
        }
        event.removeListener(bus, listener);
      }

      event.addListener(bus, listener);
      event.post(bus, 'outer');

      expect(count, 2);
      expect(heard, ['outer', 'inner']);
      expect(bus.hasListenerFor(event), isFalse);
    });
  });
}
