import 'package:flutter/material.dart';

import '../services/socket_service.dart';
import '../widgets/info_row.dart';
import '../widgets/page_body.dart';
import '../widgets/platform_notice.dart';

class SocketPage extends StatefulWidget {
  const SocketPage({super.key});

  @override
  State<SocketPage> createState() => _SocketPageState();
}

class _SocketPageState extends State<SocketPage> {
  final SocketService _service = createSocketService();
  final TextEditingController _hostController = TextEditingController(
    text: 'www.baidu.com',
  );
  final TextEditingController _portController = TextEditingController(
    text: '80',
  );
  final TextEditingController _pathController = TextEditingController(
    text: '/',
  );

  SocketProbeResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty || port == null) {
      setState(() => _error = '主机或端口不合法');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _service.httpGet(
        host: host,
        port: port,
        path: _pathController.text.trim().isEmpty
            ? '/'
            : _pathController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Socket API')),
      body: PageBody(
        child: ListView(
          children: <Widget>[
            if (!_service.supported) ...<Widget>[
              const PlatformNotice(
                message:
                    '浏览器只提供 WebSocket，没有原始 TCP Socket，'
                    '因此本页只能在 Android / Windows 上演示。'
                    'Web 端保留教材要点说明。',
              ),
              const SizedBox(height: 12),
            ] else ...<Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('TCP 连接', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: '主机',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '端口',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _pathController,
                              decoration: const InputDecoration(
                                labelText: '请求路径',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _loading ? null : _send,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('发送 HTTP GET 报文'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading) ...<Widget>[
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        LinearProgressIndicator(),
                        SizedBox(height: 8),
                        Text('等待服务器响应…'),
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
                    child: Text('请求失败：$_error'),
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
                        Text('原始响应', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        InfoRow(label: '目标', value: _result!.target),
                        InfoRow(label: '耗时', value: '${_result!.elapsedMs} ms'),
                        InfoRow(
                          label: '状态行',
                          value: _firstLine(_result!.rawResponse),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _preview(_result!.rawResponse),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '教材 11.6：Socket 要点',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Socket API 位于传输层，只负责建立连接和收发字节。'
                      'HTTP 属于应用层协议，需要自己拼装请求行、请求头与空行，'
                      '再按 UTF-8 解码服务器返回的内容。'
                      '本示例不处理重定向、Cookie 与压缩。',
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

  String _firstLine(String raw) {
    if (raw.isEmpty) {
      return '—';
    }
    return raw.split(RegExp(r'\r?\n')).first;
  }

  String _preview(String raw) {
    if (raw.length <= 8000) {
      return raw;
    }
    return '${raw.substring(0, 8000)}\n\n'
        '…（已截断，完整长度 ${raw.length} 字符）';
  }
}
