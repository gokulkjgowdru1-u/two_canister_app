import 'dart:io';
import 'dart:convert';

class UdpService {
  static const String host = '192.168.8.2';

  /// Send an ASCII string command (canisters: "2" / "3" → port 3000)
  static Future<void> send(String cmd, {int port = 3000}) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.send(utf8.encode(cmd), InternetAddress(host), port);
    socket.close();
    // ignore: avoid_print
    print('UDP SENT → $cmd → $host:$port');
  }

  /// Send a single raw byte (pump: 0x05 / 0x06 → port 9000)
  /// Matches joystick_sender.cpp exactly.
  static Future<void> sendByte(int byte, {int port = 3000}) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.send([byte & 0xFF], InternetAddress(host), port);
    socket.close();
    // ignore: avoid_print
    print(
      'UDP SENT → 0x${byte.toRadixString(16).padLeft(2, '0')} → $host:$port',
    );
  }
}
