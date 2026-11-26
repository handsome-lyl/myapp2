import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/file_service.dart';
import '../widgets/info_row.dart';
import '../widgets/page_body.dart';
import '../widgets/platform_notice.dart';

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  final FileService _service = createFileService();
  final TextEditingController _controller = TextEditingController();

  FileSnapshot? _snapshot;
  int _counter = 0;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final snapshot = await _service.load();
      final counter = await _service.readCounter();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _controller.text = snapshot.content;
        _counter = counter;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _refreshSnapshot() async {
    final snapshot = await _service.load();
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = snapshot);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await _service.save(_controller.text);
      await _refreshSnapshot();
      if (!mounted) {
        return;
      }
      _showMessage(kIsWeb ? '已保存到 localStorage' : '已保存到应用文档目录');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('保存失败：$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reload() async {
    await _loadAll();
    if (!mounted) {
      return;
    }
    _showMessage('已重新读取存储内容');
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await _service.clear();
      _controller.clear();
      await _refreshSnapshot();
      if (!mounted) {
        return;
      }
      _showMessage('文件已删除');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('删除失败：$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _increment() async {
    final next = _counter + 1;
    setState(() => _counter = next);
    try {
      await _service.writeCounter(next);
    } catch (error) {
      if (mounted) {
        _showMessage('写入计数失败：$error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modifiedAt = _snapshot?.modifiedAt;
    return Scaffold(
      appBar: AppBar(title: const Text('文件操作')),
      body: PageBody(
        child: ListView(
          children: <Widget>[
            if (kIsWeb) ...<Widget>[
              const PlatformNotice(
                message:
                    '当前运行在浏览器：浏览器没有文件系统，本页自动切换为 '
                    'localStorage 实现，保存、读取、删除和计数持久化都可正常演示。'
                    'Android / Windows 上使用 path_provider + dart:io 写入真实文件。',
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '计数持久化（教材 11.1 示例）',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前计数：$_counter',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? '每次点击写入 localStorage，刷新页面后自动恢复。'
                          : '每次点击写入 counter.txt，退出并重启应用后自动恢复。',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _increment,
                      icon: const Icon(Icons.add),
                      label: const Text('点击 +1'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('笔记文件', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: '文件内容',
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
                          onPressed: _busy ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('保存'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新读取'),
                        ),
                        TextButton.icon(
                          onPressed: _busy ? null : _delete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('删除文件'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('存储信息', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Text('读取失败：$_error')
                    else ...<Widget>[
                      InfoRow(label: '实现方式', value: _service.platformLabel),
                      InfoRow(label: '路径', value: _snapshot?.path ?? '—'),
                      InfoRow(label: '大小', value: '${_snapshot?.size ?? 0} 字节'),
                      InfoRow(
                        label: '修改时间',
                        value: modifiedAt == null
                            ? '—'
                            : _formatDate(modifiedAt),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}
