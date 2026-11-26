import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../widgets/info_row.dart';
import '../widgets/page_body.dart';

class ApiPage extends StatefulWidget {
  const ApiPage({super.key});

  @override
  State<ApiPage> createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  static const String _endpoint = 'https://dummyjson.com/posts';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  List<Post> _posts = <Post>[];
  bool _loading = true;
  String? _error;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _posts.isEmpty;
      _error = null;
    });
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get<dynamic>(
        _endpoint,
        queryParameters: <String, dynamic>{'limit': 20},
      );
      stopwatch.stop();
      final dynamic data = response.data;
      final List<dynamic> rawPosts = data is Map<String, dynamic>
          ? data['posts'] as List<dynamic>? ?? <dynamic>[]
          : <dynamic>[];
      final posts = rawPosts
          .whereType<Map<String, dynamic>>()
          .map(Post.fromJson)
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = posts;
        _elapsedMs = stopwatch.elapsedMilliseconds;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      stopwatch.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _elapsedMs = stopwatch.elapsedMilliseconds;
        if (_posts.isEmpty) {
          _error = '$error';
        }
      });
      if (_posts.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('刷新失败：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dio 请求与 JSON Model'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: '重新请求',
          ),
        ],
      ),
      body: PageBody(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _posts.isEmpty) {
      return ListView(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('请求失败', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length + 1,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _SummaryCard(
              endpoint: _endpoint,
              elapsedMs: _elapsedMs,
              count: _posts.length,
            );
          }
          final post = _posts[index - 1];
          return _PostCard(post: post, onTap: () => _showDetail(context, post));
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Post post) {
    final pretty = const JsonEncoder.withIndent('  ').convert(post.toJson());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final theme = Theme.of(sheetContext);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: <Widget>[
                Text(post.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                InfoRow(label: 'id', value: '${post.id}'),
                InfoRow(label: 'userId', value: '${post.userId}'),
                InfoRow(label: 'views', value: '${post.views}'),
                InfoRow(label: 'tags', value: post.tags.join(', ')),
                const SizedBox(height: 12),
                Text(
                  'Post.fromJson 解析后的 JSON',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      pretty,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.endpoint,
    required this.elapsedMs,
    required this.count,
  });

  final String endpoint;
  final int elapsedMs;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '11.3 dio + 11.7 JSON → Model',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('GET $endpoint?limit=20', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text('耗时 $elapsedMs ms')),
                Chip(label: Text('共 $count 条')),
                if (kIsWeb) const Chip(label: Text('Web：CORS 已开启')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '#${post.id} · ${post.title}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  ...post.tags.map(
                    (String tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      labelStyle: theme.textTheme.labelSmall,
                    ),
                  ),
                  Chip(
                    label: Text('浏览 ${post.views}'),
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
