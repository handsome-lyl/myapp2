class SocketProbeResult {
  const SocketProbeResult({
    required this.target,
    required this.rawResponse,
    required this.elapsedMs,
  });

  final String target;
  final String rawResponse;
  final int elapsedMs;
}

abstract class SocketService {
  bool get supported;

  String get implementation;

  Future<SocketProbeResult> httpGet({
    required String host,
    required int port,
    required String path,
  });
}
