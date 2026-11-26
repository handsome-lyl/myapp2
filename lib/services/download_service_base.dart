typedef DownloadProgressCallback = void Function(int received, int total);
typedef DownloadLogCallback = void Function(String message);

class DownloadResult {
  const DownloadResult({
    required this.savePath,
    required this.totalBytes,
    required this.chunkCount,
    required this.elapsedMs,
    required this.usedRange,
  });

  final String savePath;
  final int totalBytes;
  final int chunkCount;
  final int elapsedMs;
  final bool usedRange;
}

abstract class DownloadService {
  bool get supported;

  Future<DownloadResult> downloadWithChunks({
    required String url,
    required int firstChunkSize,
    required int maxChunk,
    DownloadLogCallback? onLog,
    DownloadProgressCallback? onProgress,
  });
}
