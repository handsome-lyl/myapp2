import 'download_service_base.dart';

class UnsupportedDownloadService implements DownloadService {
  @override
  bool get supported => false;

  @override
  Future<DownloadResult> downloadWithChunks({
    required String url,
    required int firstChunkSize,
    required int maxChunk,
    DownloadLogCallback? onLog,
    DownloadProgressCallback? onProgress,
  }) async {
    throw UnsupportedError('浏览器不支持 dart:io 文件系统与 dio.download');
  }
}

DownloadService createDownloadService() => UnsupportedDownloadService();
