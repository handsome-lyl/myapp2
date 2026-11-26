import 'socket_service_base.dart';

class UnsupportedSocketService implements SocketService {
  @override
  bool get supported => false;

  @override
  String get implementation => '浏览器不支持原始 TCP Socket';

  @override
  Future<SocketProbeResult> httpGet({
    required String host,
    required int port,
    required String path,
  }) async {
    throw UnsupportedError('浏览器不支持 dart:io Socket');
  }
}

SocketService createSocketService() => UnsupportedSocketService();
