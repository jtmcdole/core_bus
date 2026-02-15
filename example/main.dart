import 'dart:async';
import 'package:core_bus/core_bus.dart';

/// A simple example demonstrating the different event types available in
/// this EventBus library.
void main() async {
  final bus = EventBus();

  print('--- 1. Broadcast Event ---');
  // Broadcast events only deliver data to listeners that are active at the
  // moment of posting.
  const statusUpdate = Event<String>.broadcast(name: 'status');

  statusUpdate.addListener(bus, (status) => print('Listener 1 saw: $status'));
  statusUpdate.post(bus, 'System Booting');

  // This listener arrives late and won't see 'System Booting'
  statusUpdate.addListener(
    bus,
    (status) => print('Late Listener saw: $status'),
  );
  statusUpdate.post(bus, 'System Ready');

  await Future.delayed(const Duration(milliseconds: 1));

  print('--- 2. Single Replay Event (stream) ---');
  // Replay events cache the most recent value for any future listeners.
  const themeMode = Event<String>.replay(name: 'theme');

  themeMode.post(bus, 'Dark Mode');

  // Even though this listener is late, it immediately gets 'Dark Mode'
  themeMode.on(bus).listen((mode) => print('Late Theme Listener saw: $mode'));

  await Future.delayed(const Duration(milliseconds: 1));

  print('--- 3. Multiple Replay Events (Limit: 3) ---');
  // Replays with a limit cache the "last X" events.
  const messageHistory = Event<String>.replays(name: 'history', limit: 3);

  print('Posting 4 messages (A, B, C, D)...');
  messageHistory.post(bus, 'Message A');
  messageHistory.post(bus, 'Message B');
  messageHistory.post(bus, 'Message C');
  messageHistory.post(bus, 'Message D');

  print('New listener subscribing to history...');
  // This listener will immediately receive B, C, and D (the last 3).
  messageHistory.on(bus).listen((msg) => print('History Listener saw: $msg'));

  // Wait a moment for async delivery to finish in the console
  await Future.delayed(Duration(milliseconds: 1));

  print('--- 4. Inspection API ---');
  print('Bus has active listeners: ${bus.hasListeners}');
  print('Bus has cached replays: ${bus.hasReplays}');
  print('Last history message: ${messageHistory.lastEvent(bus)}');
  print('All cached history: ${messageHistory.events(bus).toList()}');

  await bus.reset();
  print('Bus reset. Has listeners: ${bus.hasListeners}');
}
