import 'dart:convert';
import 'dart:io';

import 'socket_service_base.dart';

class IoSocketService implements SocketService {
  @override
  bool get supported => true;

  @override
  String get implementation => 'dart:io Socket（TCP）';

  @override
  Future<SocketProbeResult> httpGet({
    required String host,
    required int port,
    required String path,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestPath = path.startsWith('/') ? path : '/$path';
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 15),
    );
    try {
      socket.writeln('GET $requestPath HTTP/1.1');
      socket.writeln('Host: $host');
      socket.writeln('Connection: close');
      socket.writeln('User-Agent: flutter-net-lab/1.0');
      socket.writeln();
      await socket.flush();

      final raw = await const Utf8Decoder(allowMalformed: true)
          .bind(socket)
          .join();
      stopwatch.stop();
      return SocketProbeResult(
        target: '$host:$port$requestPath',
        rawResponse: raw,
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      await socket.close();
    }
  }
}

SocketService createSocketService() => IoSocketService();
