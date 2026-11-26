import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/native_http_service.dart';
import '../widgets/info_row.dart';
import '../widgets/page_body.dart';
import '../widgets/platform_notice.dart';

class HttpClientPage extends StatefulWidget {
  const HttpClientPage({super.key});

  @override
  State<HttpClientPage> createState() => _HttpClientPageState();
}

class _HttpClientPageState extends State<HttpClientPage> {
  final NativeHttpService _service = createNativeHttpService();
  final TextEditingController _urlController = TextEditingController(
    text: 'https://v1.hitokoto.cn/?encode=json',
  );

  HttpProbeResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _service.get(_urlController.text.trim());
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
      appBar: AppBar(title: const Text('HttpClient')),
      body: PageBody(
        child: ListView(
          children: <Widget>[
            if (kIsWeb) ...<Widget>[
              PlatformNotice(
                message:
                    '浏览器没有 dart:io，无法直接使用 HttpClient。'
                    '本页在 Web 上使用 ${_service.implementation} 发起同样的请求，'
                    'Android / Windows 上使用教材中的 dart:io HttpClient。',
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('请求地址', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loading ? null : _send,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('发起 GET 请求'),
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
                      Text('请求中…'),
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
                      Text('响应概览', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          Chip(label: Text('HTTP ${_result!.statusCode}')),
                          Chip(label: Text('${_result!.elapsedMs} ms')),
                          Chip(label: Text(_result!.implementation)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InfoRow(label: '请求地址', value: _result!.url),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: Text('响应头（${_result!.headers.length}）'),
                  children: _result!.headers.entries
                      .map(
                        (MapEntry<String, String> entry) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: InfoRow(label: entry.key, value: entry.value),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('响应体', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SelectableText(
                        _result!.body,
                        style: theme.textTheme.bodySmall,
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
                    Text(
                      '教材 11.2：HttpClient 五步',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. 创建 HttpClient\n'
                      '2. 打开连接并设置请求头\n'
                      '3. 写入请求体（GET 可省略）\n'
                      '4. 调用 request.close() 发送并等待响应\n'
                      '5. 读取响应流并按 UTF-8 解码',
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
}
