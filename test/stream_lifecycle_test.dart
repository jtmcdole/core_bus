import 'package:test/test.dart';
import 'package:core_bus/event_bus.dart';

void main() {
  group('Stream Lifecycle', () {
    late EventBus bus;
    late Event<String> event;

    setUp(() {
      bus = EventBus();
      event = Event.broadcast(name: 'test');
    });

    test('controller is added to EventBus when on() is called', () {
      expect(bus.hasStreams, 0);
      event.on(bus);
      expect(bus.hasStreams, 1);
    });

    test(
      'controller is removed from EventBus when stream is cancelled',
      () async {
        final stream = event.on(bus);
        expect(bus.hasStreams, 1);

        final subscription = stream.listen((_) {});
        await subscription.cancel();

        expect(bus.hasStreams, 0);
      },
    );

    test('reset() closes and removes all controllers', () async {
      event.on(bus);
      event.on(bus);
      expect(bus.hasStreams, 2);

      await bus.reset();
      expect(bus.hasStreams, 0);
    });

    test('multiple listeners on same broadcast stream use same controller', () {
      final stream = event.on(bus);
      expect(bus.hasStreams, 1);

      final sub1 = stream.listen((_) {});
      final sub2 = stream.listen((_) {});
      expect(bus.hasStreams, 1);

      sub1.cancel();
      expect(bus.hasStreams, 1);

      sub2.cancel();
      expect(bus.hasStreams, 0);
    });
  });
}
