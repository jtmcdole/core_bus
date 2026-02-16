/// This library provides a centralized communication channel ([EventBus])
/// through which different parts of an application can interact without
/// direct dependencies, using [Event] objects to define the communication
/// protocol.
///
/// It aims to avoid the bottleneck of one stream for all producers and
/// listeners and instead allow for multiple buses and independent Event
/// callback distribution.
///
/// Use [Event.addListener] for high-performance direct callbacks, or
/// [Event.on] for a reactive [Stream]-based API.

import 'dart:async';
import 'dart:collection';

part 'src/broadcast_event.dart';
part 'src/replay_event.dart';

/// A callback function that receives an event of type [T].
typedef EventCallback<T> = void Function(T event);

/// Defines a single "bus" which hosts multiple asynchronous listeners.
///
/// An [EventBus] acts as a central hub for event distribution. It manages
/// active listeners and optional replayed (cached) events.
///
/// While you can use a single global bus, multiple event buses can be used
/// to isolate different parts of a system.
///
/// To interact with the bus, use [Event.post] to emit events and
/// [Event.addListener] or [Event.on] to listen for them.
///
/// ### Example:
/// ```dart
/// final bus = EventBus();
///
/// // Later...
/// await bus.reset(); // Clears everything
/// ```
final class EventBus {
  // All listeners on this bus.
  // Note to future self: `Function` used to get around dart language.
  final _listeners = <Event<Object?>, Set<Function>>{};

  final _replays = <Event<Object?>, Iterable<Object?>>{};

  final _controllers = <StreamController<Object?>>{};

  /// Whether the bus is currently in the middle of posting an event.
  bool _isPosting = false;

  // Listeners that should be removed after the current event distribution is complete.
  // Note to future self: `Function` used to get around dart language.
  final _pendingRemovals = <(Event<Object?>, Function)>[];

  /// Returns true if there are any active listeners for any event.
  ///
  /// This can be useful for debugging or optimization to check if anyone
  /// is actually listening to the bus.
  bool get hasListeners => _listeners.isNotEmpty;

  /// Returns the number of distinct [Event] types that have active listeners.
  int get listenerCount => _listeners.length;

  /// Returns true if there are any cached replays for any event on this bus.
  bool get hasReplays => _replays.isNotEmpty;

  /// Returns the number of active [StreamController]s managed by this bus.
  int get hasStreams => _controllers.length;

  /// Returns true if the given [event] has at least one cached value on this bus.
  bool hasReplayFor(Event event) => _replays.containsKey(event);

  /// Returns true if the given [event] has at least one listener.
  bool hasListenerFor(Event event) => _listeners.containsKey(event);

  /// The number of listeners for [event] on this bus.
  int listenerCountFor(Event event) => (_listeners[event] ?? const {}).length;

  /// Closes all active listeners and removes all cached replayed events.
  ///
  /// This is typically used during teardown or when resetting application state.
  /// It returns a [Future] that completes when all internal listeners
  /// have been removed.
  Future<void> reset() async {
    _listeners.clear();
    _replays.clear();
    _pendingRemovals.clear();
    for (final controller in _controllers) {
      controller.close();
    }
    _controllers.clear();
  }
}

/// Event is used to [post] events to, or listen [on], an [EventBus].
///
/// Events are identified by their [name] and type [T]. It is recommended
/// to define events as `const` top-level variables or static members to
/// ensure they can be easily shared across the application.
///
/// ### Simple Broadcast Example:
/// ```dart
/// const userLoggedIn = Event<User>.broadcast(name: 'userLoggedIn');
///
/// // Elsewhere:
/// userLoggedIn.addListener(bus, (user) => print('Welcome ${user.name}'));
///
/// // Reactive Stream:
/// userLoggedIn.on(bus).listen((user) => print('Stream: Welcome ${user.name}'));
///
/// // In another part:
/// userLoggedIn.post(bus, currentUser);
/// ```
sealed class Event<T> {
  /// The name of the event.
  ///
  /// This should be unique among events shared on the same [EventBus] to
  /// avoid unexpected behavior, especially when using `const` events.
  final String name;

  const Event._({required this.name});

  /// Creates a non-caching broadcast event.
  ///
  /// Listeners only receive events that are [post]ed after they have
  /// subscribed using [on] or [addListener].
  ///
  /// [name] must be provided for identification.
  const factory Event.broadcast({required String name}) = _BroadcastEvent<T>;

  /// Creates a caching event that replays the single most recent value.
  ///
  /// New listeners will immediately receive the last value that was [post]ed,
  /// even if it was posted before they subscribed.
  ///
  /// [name] must be provided for identification.
  const factory Event.replay({required String name}) = _SingleReplayEvent<T>;

  /// Creates a caching event that replays multiple recent values.
  ///
  /// New listeners will receive up to [limit] most recent values upon
  /// subscribing.
  ///
  /// [name] must be provided for identification.
  /// [limit] specifies the maximum number of events to cache (defaults to 1).
  const factory Event.replays({required String name, int limit}) =
      _ReplayEvent<T>;

  /// Post a new [event] value to the [bus].
  ///
  /// All active listeners on the [bus] for this specific [Event] will be
  /// notified. If this is a replay event, the [event] value will also
  /// be cached for future listeners.
  void post(EventBus bus, T event);

  /// Adds a [callback] to be notified when events are posted to the [bus].
  ///
  /// Direct callbacks provide the highest performance by avoiding [Stream]
  /// overhead.
  ///
  /// If this is a replay event, the [callback] will immediately be called
  /// with any currently cached values.
  void addListener(EventBus bus, EventCallback<T> callback);

  /// Removes a previously added [callback] from the [bus].
  void removeListener(EventBus bus, EventCallback<T> callback);

  /// Whether any events have been posted to the [bus] and are currently cached.
  ///
  /// Only returns true for caching events ([replay] or [replays]) that have
  /// had at least one event [post]ed.
  bool hasLastEvent(EventBus bus);

  /// Returns the most recent event value posted to [bus].
  ///
  /// Returns `null` if no event has been posted yet or if this is a
  /// non-caching [broadcast] event.
  T? lastEvent(EventBus bus);

  /// Returns an [Iterable] of all currently cached event values on the [bus].
  ///
  /// For [broadcast] events, this always returns an empty iterable.
  /// For [replay] events, this returns an iterable containing at most one item.
  /// For [replays] events, this returns an iterable containing up to [limit] items.
  Iterable<T> events(EventBus bus);

  /// Removes all replay event values for this event from the [bus].
  ///
  /// This only affects future listeners.
  void clearReplays(EventBus bus);

  /// Closes all internal listeners for this event on the [bus].
  ///
  /// This effectively unsubscribes all current listeners.
  Future<void> close(EventBus bus) async {
    bus._listeners.remove(this);
  }
}

/// Provides a [Stream]-based API for [Event]s.
extension EventStreamExtension<T> on Event<T> {
  /// Returns a [Stream] of events posted to the [bus].
  ///
  /// This is a convenience wrapper around [addListener] and [removeListener]
  /// for use with Dart's reactive programming patterns.
  ///
  /// If this is a replay event, the stream will immediately emit any
  /// cached values before emitting new events.
  Stream<T> on(EventBus bus, {bool sync = false}) {
    late StreamController<T> controller;
    void listener(T event) => controller.add(event);

    controller = StreamController<T>.broadcast(
      sync: sync,
      onListen: () => addListener(bus, listener),
      onCancel: () {
        bus._controllers.remove(controller);
        removeListener(bus, listener);
      },
    );
    bus._controllers.add(controller);

    return controller.stream;
  }
}
