class HttpProbeResult {
  const HttpProbeResult({
    required this.url,
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.elapsedMs,
    required this.implementation,
  });

  final String url;
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final int elapsedMs;
  final String implementation;
}

abstract class NativeHttpService {
  String get implementation;

  Future<HttpProbeResult> get(String url);
}
