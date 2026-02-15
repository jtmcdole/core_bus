# Product Guidelines

## API Design Principles
- **Performance First:** The core API should prioritize low latency and minimal object allocation. Callbacks are preferred over more heavyweight abstractions in the hot path.
- **Explicit over Implicit:** API behavior should be clear and predictable. Avoid hidden side effects or complex automatic state management.
- **Safety and Soundness:** Leverage Dart's sound null safety and strong typing to provide a robust developer experience.

## Documentation Standards
- **Runnable Examples:** Maintain a comprehensive `example/` directory with clear, self-contained examples for every major feature.
- **Exhaustive API Documentation:** Every public class, method, and property must have a clear `dartdoc` comment explaining its purpose, parameters, and return values.
- **Prose Clarity:** Documentation should be concise, professional, and free of jargon, making it accessible to both new and experienced Dart developers.

## Engineering Standards
- **Zero-Dependency Core:** Minimize external dependencies in `pubspec.yaml` to ensure a lightweight footprint and easy integration into any project.
- **High Test Fidelity:** Maintain a minimum of 90% test coverage for all core logic, focusing on unit tests for event distribution, replay mechanisms, and subscription lifecycles.
- **Strict Typing:** Avoid `dynamic` or untyped collections. Use generics effectively to provide compile-time safety and enable compiler optimizations.
- **Platform Neutrality:** Ensure the library is fully compatible and performant on all Dart supported platforms (Flutter, CLI, Server, Web).
