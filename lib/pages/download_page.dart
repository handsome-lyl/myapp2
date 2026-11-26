import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/download_service.dart';
import '../widgets/info_row.dart';
import '../widgets/page_body.dart';
import '../widgets/platform_notice.dart';

const String _defaultUrl =
    'https://mirrors.tuna.tsinghua.edu.cn/ubuntu/dists/noble/main/binary-amd64/Packages.gz';
const int _firstChunkSize = 256 * 1024;
const int _maxChunk = 3;

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final DownloadService _service = createDownloadService();
  final TextEditingController _urlController = TextEditingController(
    text: _defaultUrl,
  );
  final List<String> _logs = <String>[];

  bool _running = false;
  double _progress = 0;
  DownloadResult? _result;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_running || !_service.supported) {
      return;
    }
    setState(() {
      _running = true;
      _progress = 0;
      _logs.clear();
      _result = null;
      _error = null;
    });
    try {
      final result = await _service.downloadWithChunks(
        url: _urlController.text.trim(),
        firstChunkSize: _firstChunkSize,
        maxChunk: _maxChunk,
        onLog: (String message) {
          if (!mounted) {
            return;
          }
          setState(() => _logs.add(message));
        },
        onProgress: (int received, int total) {
          if (!mounted || total <= 0) {
            return;
          }
          final value = (received / total).clamp(0.0, 1.0).toDouble();
          if ((value - _progress).abs() >= 0.01 || value >= 1) {
            setState(() => _progress = value);
          }
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _progress = 1;
        _running = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('分块下载')),
      body: PageBody(
        child: ListView(
          children: <Widget>[
            if (kIsWeb) ...<Widget>[
              const PlatformNotice(
                message:
                    '浏览器不能直接写文件系统，也不支持 dio.download，'
                    '因此分块下载只在 Android / Windows 上运行。'
                    '此页在 Web 端保留原理说明，下载按钮不可用。',
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('下载地址', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '首块 256 KB，最多 3 个并发分块；依赖服务器返回 206 与 Content-Range。',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: !_service.supported || _running
                          ? null
                          : _start,
                      icon: const Icon(Icons.download),
                      label: Text(_running ? '下载中…' : '开始分块下载'),
                    ),
                  ],
                ),
              ),
            ),
            if (_running) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text(
                        '总进度 ${(_progress * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('下载失败：$_error'),
                ),
              ),
            ],
            if (_result != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('下载结果', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      InfoRow(label: '保存路径', value: _result!.savePath),
                      InfoRow(
                        label: '文件大小',
                        value: _formatBytes(_result!.totalBytes),
                      ),
                      InfoRow(label: '分块数', value: '${_result!.chunkCount}'),
                      InfoRow(label: '耗时', value: '${_result!.elapsedMs} ms'),
                      InfoRow(
                        label: '206 分块',
                        value: _result!.usedRange ? '是' : '否（整文件下载）',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_logs.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('下载日志', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._logs.map(
                        (String line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(line, style: theme.textTheme.bodySmall),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('教材 11.4：分块下载原理', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '1. 先请求 Range: bytes=0-首块大小，检测是否返回 206\n'
                      '2. 从 Content-Range 读取文件总长度\n'
                      '3. 把剩余内容拆成多个分块并发下载到临时文件\n'
                      '4. 按序号合并临时文件并删除\n'
                      '5. 最后把合并文件重命名为目标文件名',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes 字节';
  }
}
