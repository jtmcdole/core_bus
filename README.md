# core_bus

```txt
core_bus
   (  >
    \/\
     ^^
A small, tight, and type-safe Event Bus for Dart.
```

Unlike traditional event buses that use a single global stream of `dynamic` objects, `core_bus` gives each event its own typed stream. This eliminates manual casting and improves performance by only notifying relevant listeners.

## Features

* **Small & Tight:** No external dependencies other than `meta` and `test`.
* **Type-Safe:** Leverage Dart's type system to ensure listeners receive the correct data types.
* **Optional Replay:** New listeners can automatically receive the last $N$ events emitted.
* **Decoupled:** Ideal for large applications or game engines (like Flame) where decoupling is critical.

## Getting Started

Define your events as constants:

```dart
const userLogin = Event<String>.broadcast(name: 'userLogin');
const themeColor = Event<Color>.replay(name: 'themeColor', limit: 1);
```

Listen and post:

```dart
final bus = EventBus();

userLogin.on(bus).listen((name) => print('Hello, $name!'));

userLogin.post(bus, 'codefu');
```

## Performance

This library is designed for high-performance and minimal object allocation. 

* **Direct Callbacks:** For performance-critical code, use `addListener` / `removeListener`. This bypasses Dart's `StreamController` overhead and is significantly faster.
* **Reactive Streams:** Use `.on(bus)` for a convenient reactive API when convenience is more important than raw throughput.

### Benchmarks

Running the included benchmark (`dart run benchmark/speed_benchmark.dart`) typically shows that the Callback API is **~2.5x - 3x faster** than the Stream API for high-frequency event distribution.

| API | Speed (Avg) |
| :--- | :--- |
| **Callback API** | ~0.06μs per post |
| **Stream API (Sync)** | ~0.17μs per post |

