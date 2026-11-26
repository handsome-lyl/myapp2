import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'download_service_base.dart';

class IoDownloadService implements DownloadService {
  @override
  bool get supported => true;

  @override
  Future<DownloadResult> downloadWithChunks({
    required String url,
    required int firstChunkSize,
    required int maxChunk,
    DownloadLogCallback? onLog,
    DownloadProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/downloads');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final savePath = '${directory.path}/${_fileNameFromUrl(url)}';

    for (var i = 0; i <= maxChunk; i++) {
      final temp = File('$savePath.temp$i');
      if (await temp.exists()) {
        await temp.delete();
      }
    }
    final existing = File(savePath);
    if (await existing.exists()) {
      await existing.delete();
    }

    final progress = <int>[];
    var total = 0;

    Future<Response<dynamic>> downloadChunk(
      int start,
      int end,
      int index,
    ) async {
      progress.add(0);
      final realEnd = end - 1;
      onLog?.call('分块 $index：请求 Range bytes=$start-$realEnd');
      final response = await dio.download(
        url,
        '$savePath.temp$index',
        options: Options(
          headers: <String, dynamic>{'range': 'bytes=$start-$realEnd'},
        ),
        onReceiveProgress: (int received, int _) {
          progress[index] = received;
          if (total > 0) {
            final receivedTotal = progress.fold<int>(
              0,
              (int sum, int value) => sum + value,
            );
            onProgress?.call(receivedTotal, total);
          }
        },
      );
      onLog?.call('分块 $index：完成 HTTP ${response.statusCode}');
      return response;
    }

    var chunkCount = 1;
    var usedRange = false;
    final first = await downloadChunk(0, firstChunkSize, 0);

    if (first.statusCode == HttpStatus.partialContent) {
      usedRange = true;
      final contentRange = first.headers.value(HttpHeaders.contentRangeHeader);
      if (contentRange != null && contentRange.contains('/')) {
        total = int.tryParse(contentRange.split('/').last) ?? 0;
      }
      final firstLength =
          int.tryParse(
            first.headers.value(HttpHeaders.contentLengthHeader) ?? '',
          ) ??
          firstChunkSize;
      final reserved = total - firstLength;
      chunkCount = (reserved / firstChunkSize).ceil() + 1;
      onLog?.call('服务器支持分块传输：总大小 $total 字节，初始计划 $chunkCount 块');

      if (chunkCount > 1) {
        var chunkSize = firstChunkSize;
        if (chunkCount > maxChunk + 1) {
          chunkCount = maxChunk + 1;
          chunkSize = (reserved / maxChunk).ceil();
          onLog?.call('分块数超过并发上限，调整为 $chunkCount 块，每块约 $chunkSize 字节');
        }
        final futures = <Future<Response<dynamic>>>[];
        for (var i = 0; i < maxChunk; i++) {
          final start = firstChunkSize + i * chunkSize;
          futures.add(downloadChunk(start, start + chunkSize, i + 1));
        }
        await Future.wait(futures);
      }
      await _merge(savePath, chunkCount, onLog);
    } else {
      total =
          int.tryParse(
            first.headers.value(HttpHeaders.contentLengthHeader) ?? '',
          ) ??
          0;
      onLog?.call('服务器未返回 206（状态码 ${first.statusCode}），改为普通整文件下载');
      final temp = File('$savePath.temp0');
      await temp.rename(savePath);
    }

    stopwatch.stop();
    final length = await File(savePath).length();
    onLog?.call('下载完成：$savePath（$length 字节）');
    return DownloadResult(
      savePath: savePath,
      totalBytes: length,
      chunkCount: chunkCount,
      elapsedMs: stopwatch.elapsedMilliseconds,
      usedRange: usedRange,
    );
  }

  Future<void> _merge(
    String savePath,
    int chunkCount,
    DownloadLogCallback? onLog,
  ) async {
    onLog?.call('开始合并 $chunkCount 个临时文件');
    final target = File('$savePath.temp0');
    final sink = target.openWrite(mode: FileMode.writeOnlyAppend);
    for (var i = 1; i < chunkCount; i++) {
      final part = File('$savePath.temp$i');
      if (await part.exists()) {
        await sink.addStream(part.openRead());
        await part.delete();
      }
    }
    await sink.close();
    final output = File(savePath);
    if (await output.exists()) {
      await output.delete();
    }
    await target.rename(savePath);
  }

  String _fileNameFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final raw = segments.isEmpty || segments.last.isEmpty
        ? 'chapter11_download.bin'
        : segments.last;
    return raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}

DownloadService createDownloadService() => IoDownloadService();
