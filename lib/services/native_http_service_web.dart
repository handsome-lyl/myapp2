import 'package:dio/dio.dart';

import 'native_http_service_base.dart';

class WebNativeHttpService implements NativeHttpService {
  final Dio _dio = Dio();

  @override
  String get implementation => '浏览器 XMLHttpRequest（dio BrowserAdapter）';

  @override
  Future<HttpProbeResult> get(String url) async {
    final stopwatch = Stopwatch()..start();
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    stopwatch.stop();

    final headers = <String, String>{};
    response.headers.forEach((String name, List<String> values) {
      headers[name] = values.join(', ');
    });

    return HttpProbeResult(
      url: url,
      statusCode: response.statusCode ?? 0,
      headers: headers,
      body: response.data ?? '',
      elapsedMs: stopwatch.elapsedMilliseconds,
      implementation: implementation,
    );
  }
}

NativeHttpService createNativeHttpService() => WebNativeHttpService();
