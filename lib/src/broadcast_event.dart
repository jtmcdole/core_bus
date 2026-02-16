part of '../core_bus.dart';

/// A non-caching [Event] implementation.
///
/// Listeners to this event will only receive data that is posted *after*
/// they have subscribed to the [EventBus].
final class _BroadcastEvent<T> extends Event<T> {
  const _BroadcastEvent({required super.name}) : super._();

  @override
  void post(EventBus bus, T event) {
    final set = bus._listeners[this] ?? const {};

    final wasPosting = bus._isPosting;
    bus._isPosting = true;

    try {
      for (final callback in set) {
        (callback as EventCallback<T>)(event);
      }
    } finally {
      if (!wasPosting) {
        bus._isPosting = false;
        // Process pending removals after the top-level post is complete.
        if (bus._pendingRemovals.isNotEmpty) {
          for (final removal in bus._pendingRemovals) {
            (removal.$1 as Event<T>).removeListener(
              bus,
              removal.$2 as EventCallback<T>,
            );
          }
          bus._pendingRemovals.clear();
        }
      }
    }
  }

  @override
  void addListener(EventBus bus, EventCallback<T> callback) {
    final set = bus._listeners[this] ??= <Function>{};
    set.add(callback);
  }

  @override
  void removeListener(EventBus bus, EventCallback<T> callback) {
    if (bus._isPosting) {
      bus._pendingRemovals.add((this, callback));
      return;
    }

    final set = bus._listeners[this];
    if (set != null) {
      set.remove(callback);
      if (set.isEmpty) {
        bus._listeners.remove(this);
      }
    }
  }

  @override
  bool hasLastEvent(EventBus bus) => false;

  @override
  T? lastEvent(EventBus bus) => null;

  @override
  Iterable<T> events(EventBus bus) => const [];

  @override
  void clearReplays(EventBus bus) {
    // No-op for broadcast events.
  }
}
