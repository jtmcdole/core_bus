import 'package:test/test.dart';
import 'package:core_bus/core_bus.dart';

main() {
  group('Broadcast events', () {
    late EventBus bus;
    late Event<String> event;

    setUp(() {
      bus = EventBus();
      event = Event.broadcast(name: 'broadcast');
    });

    test('send nothing with no listeners', () {
      expect(bus.hasListeners, isFalse);
      event.post(bus, 'test');
      expect(bus.hasListeners, isFalse);
    });

    test('can be subscribed to', () async {
      expect(bus.hasListeners, isFalse);

      String? lastEvent;
      var count = 0;

      event.on(bus).listen((d) {
        lastEvent = d;
        count++;
      });

      expect(bus.hasListeners, isTrue);

      event.post(bus, 'test2');
      await Future.microtask(() {});

      expect(count, 1);
      expect(lastEvent, 'test2');
    });

    test('can be unsubscribed to', () async {
      expect(bus.hasListeners, isFalse);
      final sub = event.on(bus).listen((d) {});
      expect(bus.hasListeners, isTrue);

      await sub.cancel();
      expect(bus.hasListeners, isFalse);
    });

    test('can have multiple listeners', () async {
      var counts = <int>[0, 0];
      var subs = [
        event.on(bus).listen((event) {
          counts[0]++;
        }),
        event.on(bus).listen((event) {
          counts[1]++;
        }),
      ];

      event.post(bus, 'test');
      await Future.microtask(() {});

      expect(counts, [1, 1]);

      for (final s in subs) {
        await s.cancel();
      }
    });

    test('does not cache for late listeners', () async {
      var lastSeen = <String?>[null, null];
      var counts = <int>[0, 0];
      var subs = [
        event.on(bus).listen((event) {
          counts[0]++;
          lastSeen[0] = event;
        }),
      ];

      event.post(bus, 'test');
      await Future.microtask(() {});

      expect(counts, [1, 0]);
      expect(lastSeen, ['test', null]);

      subs.add(
        event.on(bus).listen((event) {
          counts[1]++;
          lastSeen[1] = event;
        }),
      );

      event.post(bus, 'test2');
      await Future.microtask(() {});

      expect(counts, [2, 1]);
      expect(lastSeen, ['test2', 'test2']);
      for (final s in subs) {
        await s.cancel();
      }
    });
  });

  group('Replay', () {
    late EventBus bus;
    late Event<String?> event;

    setUp(() {
      bus = EventBus();
      event = Event<String?>.replay(name: 'replay');
    });

    test('caches with no listeners', () async {
      expect(bus.hasReplays, isFalse);
      event.post(bus, 'test');
      expect(bus.hasReplays, isTrue);
      expect(event.lastEvent(bus), 'test');
    });

    test('can be subscribed to', () async {
      expect(bus.hasListeners, isFalse);

      String? lastEvent;
      var count = 0;

      event.on(bus).listen((d) {
        lastEvent = d;
        count++;
      });

      expect(bus.hasListeners, isTrue);

      event.post(bus, 'test2');
      await Future.microtask(() {});

      expect(count, 1);
      expect(lastEvent, 'test2');
    });

    test('can be unsubscribed to', () async {
      expect(bus.hasListeners, isFalse);
      final sub = event.on(bus).listen((d) {});
      expect(bus.hasListeners, isTrue);

      event.post(bus, 'not disposed');

      await sub.cancel();
      expect(bus.hasListeners, isFalse);
      expect(event.lastEvent(bus), 'not disposed');
    });

    test('can have replays removed', () async {
      event.on(bus).listen((d) {});
      event.post(bus, 'to be disposed');
      await Future.microtask(() {});
      expect(event.lastEvent(bus), 'to be disposed');

      event.clearReplays(bus);
      expect(event.hasLastEvent(bus), isFalse);
    });

    test('can have multiple listeners', () async {
      var counts = <int>[0, 0];
      var subs = [
        event.on(bus).listen((event) {
          counts[0]++;
        }),
        event.on(bus).listen((event) {
          counts[1]++;
        }),
      ];

      event.post(bus, 'test');
      await Future.microtask(() {});

      expect(counts, [1, 1]);

      for (final s in subs) {
        await s.cancel();
      }
    });

    test('caches for later listeners', () async {
      var lastSeen = <String?>[null, null];
      var counts = <int>[0, 0];
      var subs = [
        event.on(bus).listen((event) {
          counts[0]++;
          lastSeen[0] = event;
        }),
      ];

      event.post(bus, 'test');
      await Future.microtask(() {});

      expect(counts, [1, 0]);
      expect(lastSeen, ['test', null]);

      subs.add(
        event.on(bus).listen((event) {
          counts[1]++;
          lastSeen[1] = event;
        }),
      );
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(counts, [1, 1]);
      expect(lastSeen, ['test', 'test']);

      event.post(bus, 'test2');
      await Future.microtask(() {});

      expect(counts, [2, 2]);
      expect(lastSeen, ['test2', 'test2']);
      for (final s in subs) {
        await s.cancel();
      }
    });

    test('hasLastEvent', () async {
      expect(event.hasLastEvent(bus), isFalse);
      expect(event.lastEvent(bus), isNull);

      event.post(bus, null);

      expect(event.hasLastEvent(bus), isTrue);
      expect(event.lastEvent(bus), isNull);

      event.post(bus, 'test');

      expect(event.hasLastEvent(bus), isTrue);
      expect(event.lastEvent(bus), 'test');
    });

    test('replays multiple events with a limit', () async {
      final multiEvent = Event<int>.replays(name: 'multi', limit: 3);
      multiEvent.post(bus, 1);
      multiEvent.post(bus, 2);
      multiEvent.post(bus, 3);
      multiEvent.post(bus, 4);

      expect(multiEvent.events(bus), [2, 3, 4]);
      expect(multiEvent.lastEvent(bus), 4);

      final seen = <int>[];
      multiEvent.on(bus).listen(seen.add);
      // Flush microtasks multiple times to ensure all queued events are processed
      await Future.microtask(() {});
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(seen, [2, 3, 4]);
    });
  });

  group('EventBus', () {
    late EventBus bus;
    late Event<String> event1;
    late Event<String> event2;

    setUp(() {
      bus = EventBus();
      event1 = Event.broadcast(name: 'one');
      event2 = Event.replay(name: 'two');
    });

    test('reset clears listeners and replays', () async {
      bool canceled1 = false;
      bool canceled2 = false;
      event1
          .on(bus)
          .listen(
            (event) {},
            onDone: () {
              canceled1 = true;
            },
          );
      event2
          .on(bus)
          .listen(
            (event) {},
            onDone: () {
              canceled2 = true;
            },
          );

      event1.post(bus, "1");
      event2.post(bus, "2");

      await Future.microtask(() {});

      expect(event2.lastEvent(bus), '2');
      expect(canceled1, isFalse);
      expect(canceled2, isFalse);

      await bus.reset();
      expect(bus.hasReplays, isFalse);
      expect(bus.hasListeners, isFalse);
      expect(canceled1, isTrue);
      expect(canceled2, isTrue);
    });
  });
}
