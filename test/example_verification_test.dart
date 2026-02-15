import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('example compiles and runs', () async {
    final result = await Process.run('dart', ['run', 'example/main.dart']);
    if (result.exitCode != 0) {
      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');
    }

    expect(result.exitCode, 0, reason: 'Example should run successfully');

    expect(
      LineSplitter.split(result.stdout),
      containsAllInOrder([
        '--- 1. Broadcast Event ---',
        'Listener 1 saw: System Booting',
        'Listener 1 saw: System Ready',
        'Late Listener saw: System Ready',
        '--- 2. Single Replay Event (stream) ---',
        'Late Theme Listener saw: Dark Mode',
        '--- 3. Multiple Replay Events (Limit: 3) ---',
        'Posting 4 messages (A, B, C, D)...',
        'New listener subscribing to history...',
        'History Listener saw: Message B',
        'History Listener saw: Message C',
        'History Listener saw: Message D',
        '--- 4. Inspection API ---',
        'Bus has active listeners: true',
        'Bus has cached replays: true',
        'Last history message: Message D',
        'All cached history: [Message B, Message C, Message D]',
        'Bus reset. Has listeners: false',
      ]),
    );
  });
}
