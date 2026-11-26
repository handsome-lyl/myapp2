import 'dart:convert';

import 'package:flutter/material.dart';

import '../widgets/page_body.dart';

const String _sampleJson = '''{
  "id": 1,
  "title": "His mother had always taught him",
  "body": "He never looked down on those who were less fortunate.",
  "tags": ["history", "american", "crime"],
  "views": 305,
  "userId": 121
}''';

const String _modelCode = '''factory Post.fromJson(Map<String, dynamic> json) {
  return Post(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String,
    body: json['body'] as String,
    tags: (json['tags'] as List).cast<String>(),
    views: (json['views'] as num).toInt(),
    userId: (json['userId'] as num).toInt(),
  );
}

Map<String, dynamic> toJson() => {
  'id': id,
  'title': title,
  'body': body,
  'tags': tags,
  'views': views,
  'userId': userId,
};''';

class JsonPage extends StatefulWidget {
  const JsonPage({super.key});

  @override
  State<JsonPage> createState() => _JsonPageState();
}

class _JsonPageState extends State<JsonPage> {
  final TextEditingController _controller = TextEditingController(
    text: _sampleJson,
  );

  String _output = '';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _format() {
    _decode(pretty: true);
  }

  void _minify() {
    _decode(pretty: false);
  }

  void _decode({required bool pretty}) {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = '请输入 JSON 内容';
        _output = '';
      });
      return;
    }
    try {
      final dynamic decoded = jsonDecode(text);
      setState(() {
        _output = pretty
            ? const JsonEncoder.withIndent('  ').convert(decoded)
            : jsonEncode(decoded);
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = 'JSON 解析失败：$error';
        _output = '';
      });
    }
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _output = '';
      _error = null;
    });
  }

  void _reset() {
    _controller.text = _sampleJson;
    setState(() {
      _output = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('JSON 工具')),
      body: PageBody(
        child: ListView(
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('JSON 文本', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: '输入 JSON',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _format,
                          icon: const Icon(Icons.format_align_left),
                          label: const Text('格式化'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _minify,
                          icon: const Icon(Icons.compress),
                          label: const Text('压缩'),
                        ),
                        TextButton.icon(
                          onPressed: _clear,
                          icon: const Icon(Icons.clear),
                          label: const Text('清空'),
                        ),
                        TextButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.restore),
                          label: const Text('示例'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!),
                ),
              ),
            ],
            if (_output.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('处理结果', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SelectableText(_output, style: theme.textTheme.bodySmall),
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
                      '11.7 JSON → Dart Model',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'json.decode() 只能得到 Map / List，业务代码应把它转换成有类型的 Model。'
                      '下面是本项目 Post 模型的手写映射代码：',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _modelCode,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '教材 11.7.2 / 11.7.3 还介绍了 json_serializable + build_runner '
                      '自动生成 fromJson/toJson，适合字段较多的项目。',
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
