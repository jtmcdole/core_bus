# core_bus

## 1.0.0

* Initial release.
* Support for `BroadcastEvent` (non-caching).
* Support for `ReplayEvent` (caching with configurable limits).
* Optimized `EventBus` with individual stream controllers per event.
* Added `reset()` to cleanly dispose of all bus listeners.
