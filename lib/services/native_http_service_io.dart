import 'dart:convert';
import 'dart:io';

import 'native_http_service_base.dart';

class IoNativeHttpService implements NativeHttpService {
  @override
  String get implementation => 'dart:io HttpClient';

  @override
  Future<HttpProbeResult> get(String url) async {
    final stopwatch = Stopwatch()..start();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'flutter-net-lab/1.0');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      stopwatch.stop();

      final headers = <String, String>{};
      response.headers.forEach((String name, List<String> values) {
        headers[name] = values.join(', ');
      });

      return HttpProbeResult(
        url: url,
        statusCode: response.statusCode,
        headers: headers,
        body: body,
        elapsedMs: stopwatch.elapsedMilliseconds,
        implementation: implementation,
      );
    } finally {
      client.close(force: true);
    }
  }
}

NativeHttpService createNativeHttpService() => IoNativeHttpService();
