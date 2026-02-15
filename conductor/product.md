# Initial Concept
Just another EventBus with optional replay using plain old streams.

# Product Guide

## Vision
A high-performance, decoupled event bus for the Dart ecosystem, supporting mobile, web, and server-side platforms. It leverages named constant events and robust replay capabilities to facilitate clean architecture and efficient asynchronous communication.

## Target Audience
- Dart/Flutter developers building complex, decoupled applications.
- Backend developers using Dart for high-performance microservices.
- Library authors seeking a lightweight and efficient event distribution system.

## Core Value Propositions
- **Decoupled Communication:** Uses named constant events to identify communication channels, reducing direct dependencies between modules.
- **Replay Support:** Built-in capability to cache and replay historical events to new listeners, ensuring they have the necessary context upon subscription.
- **Performance First:** A lean callback-based core API designed for high throughput across all Dart runtimes (JIT, AOT, Web).
- **Flexible API:** Offers both a high-performance callback API and a convenient Stream-based API via extensions.

## Strategic Goals
- **Architectural Refactor:** Transition the core engine from Stream-based to callback-based to minimize overhead and maximize performance.
- **Enhanced DX:** Provide seamless Stream extensions to maintain the familiar reactive programming model while benefiting from the optimized core.
- **Robust Subscription Management:** Implement cancelable handles for efficient resource management and listener lifecycle control.
- **Universal Compatibility:** Ensure optimal performance and reliability across Flutter, server-side Dart, and web environments (JS/Wasm).
