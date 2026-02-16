part of '../core_bus.dart';

/// An [Event] implementation that caches and replays the single most recent
/// value to new listeners.
///
/// This is an optimized version of [_ReplayEvent] where [limit] is 1.
final class _SingleReplayEvent<T> extends _ReplayEvent<T> {
  const _SingleReplayEvent({required super.name}) : super(limit: 1);

  @override
  void post(EventBus bus, T event) {
    // Notify active listeners.
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

    // Cache the value.
    final list = (bus._replays[this] ??= <T>[]) as List<T>;
    if (list.isEmpty) {
      list.add(event);
    } else {
      list[0] = event;
    }
  }

  @override
  void addListener(EventBus bus, EventCallback<T> callback) {
    super.addListener(bus, callback);
  }

  @override
  T? lastEvent(EventBus bus) {
    final list = bus._replays[this] as List<T>?;
    if (list != null && list.isNotEmpty) return list[0];
    return null;
  }

  @override
  bool hasLastEvent(EventBus bus) => bus._replays.containsKey(this);

  @override
  Iterable<T> events(EventBus bus) {
    final list = bus._replays[this] as List<T>?;
    return list ?? const [];
  }
}

/// An [Event] implementation that caches and replays multiple recent values
/// to new listeners.
final class _ReplayEvent<T> extends Event<T> {
  /// The maximum number of events to cache and replay.
  final int limit;

  const _ReplayEvent({required super.name, this.limit = 1}) : super._();

  @override
  void post(EventBus bus, T event) {
    // Notify active listeners.
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

    // Update the cache queue.
    final queue = (bus._replays[this] ??= Queue<T>()) as Queue<T>;
    queue.addLast(event);
    if (queue.length > limit) {
      queue.removeFirst();
    }
  }

  @override
  void addListener(EventBus bus, EventCallback<T> callback) {
    final set = bus._listeners[this] ??= <Function>{};
    set.add(callback);

    // Replay cached values to the new listener immediately.
    final queue = bus._replays[this] ?? const [];
    for (final event in queue) {
      callback(event as T);
    }
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
  bool hasLastEvent(EventBus bus) => bus._replays[this]?.isNotEmpty ?? false;

  @override
  T? lastEvent(EventBus bus) => bus._replays[this]?.lastOrNull as T?;

  @override
  Iterable<T> events(EventBus bus) => bus._replays[this]?.cast<T>() ?? const [];

  @override
  void clearReplays(EventBus bus) {
    bus._replays.remove(this);
  }
}
