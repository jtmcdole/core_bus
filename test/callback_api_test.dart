import 'package:test/test.dart';
import 'package:core_bus/core_bus.dart';

void main() {
  group('Callback API', () {
    late EventBus bus;
    late Event<String> event;

    setUp(() {
      bus = EventBus();
      event = Event.broadcast(name: 'test');
    });

    test('can add and receive events via callback', () {
      String? received;
      void listener(String data) {
        received = data;
      }

      event.addListener(bus, listener);
      event.post(bus, 'hello');
      expect(received, 'hello');

      event.removeListener(bus, listener);
    });

    test('can remove listener', () {
      int count = 0;
      void listener(String data) {
        count++;
      }

      event.addListener(bus, listener);
      event.post(bus, 'first');
      expect(count, 1);

      event.removeListener(bus, listener);
      event.post(bus, 'second');
      expect(count, 1);
    });

    test('multiple listeners', () {
      int count1 = 0;
      int count2 = 0;
      event.addListener(bus, (_) => count1++);
      event.addListener(bus, (_) => count2++);

      event.post(bus, 'event');
      expect(count1, 1);
      expect(count2, 1);
    });

    test('replay events to new listeners', () {
      final replayEvent = Event<int>.replay(name: 'replay');
      replayEvent.post(bus, 42);

      int? received;
      replayEvent.addListener(bus, (data) => received = data);

      expect(received, 42);
    });

    test('replays multiple events to new listeners', () {
      final replaysEvent = Event<int>.replays(name: 'replays', limit: 2);
      replaysEvent.post(bus, 1);
      replaysEvent.post(bus, 2);
      replaysEvent.post(bus, 3);

      final received = <int>[];
      replaysEvent.addListener(bus, received.add);

      expect(received, [2, 3]);
    });
  });
}
