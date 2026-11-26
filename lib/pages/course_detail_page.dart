import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course_recommend.dart';
import '../services/course_db.dart';
import '../services/course_recommend_data.dart';

/// 课程详情页
///
/// 简介来源优先级：
/// 1. 内置课程库（全平台可用，离线）
/// 2. 百度百科 API（仅 Android/Windows 等 IO 平台，浏览器有 CORS 限制）
/// 3. 都取不到时，提供「在百度百科中查看」按钮跳转网页
class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, required this.courseName});

  final String courseName;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  BaikeCourseIntro? _intro;
  String _source = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIntro();
  }

  /// 百度百科词条地址
  String get _baikeUrl =>
      'https://baike.baidu.com/item/${Uri.encodeComponent(widget.courseName)}';

  Future<void> _loadIntro() async {
    setState(() {
      _loading = true;
      _error = null;
      _intro = null;
      _source = '';
    });

    // 1. 内置课程库（离线，全平台）
    final local = CourseDb.instance.find(widget.courseName);
    if (local != null) {
      setState(() {
        _intro = BaikeCourseIntro(
          title: local.name,
          description:
              '${local.discipline} · ${local.category} · ${local.type}',
          abstract: local.description,
          url: _baikeUrl,
        );
        _source = '内置课程库';
        _loading = false;
      });
      return;
    }

    // 2. Web 端受浏览器 CORS 限制，无法请求百度百科，直接进入兜底
    if (kIsWeb) {
      setState(() => _loading = false);
      return;
    }

    // 3. IO 端（Android/Windows）尝试百度百科接口
    try {
      final uri = Uri.parse(
        'https://baike.baidu.com/api/openapi/BaikeLemmaCardApi?scope=103&format=json&appid=379020&bk_key=${Uri.encodeComponent(widget.courseName)}',
      );
      final response = await _dio.getUri<dynamic>(uri);
      final data = response.data;
      if (data is! Map<String, dynamic> || data['id'] == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '未找到该课程的百科条目';
        });
        return;
      }
      final String abstract = data['abstract'] as String? ?? '';
      if (!mounted) return;
      setState(() {
        _intro = BaikeCourseIntro(
          title: data['title'] as String? ?? widget.courseName,
          description: data['desc'] as String? ?? '',
          abstract: abstract,
          url: data['url'] as String? ?? _baikeUrl,
        );
        _source = '百度百科';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '网络请求失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommends = findRecommendsFor(widget.courseName);
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('课程简介', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildIntroSection(theme),
          const SizedBox(height: 24),
          Text('推荐教程', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildRecommendList(theme, recommends),
        ],
      ),
    );
  }

  Widget _buildIntroSection(ThemeData theme) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('正在获取课程介绍…'),
            ],
          ),
        ),
      );
    }

    final intro = _intro;
    if (intro == null) {
      // 兜底：内置库与百科接口都没有，提供跳转入口
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_error ?? '该课程暂未收录本地课程库', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _openUrl(_baikeUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('在百度百科中查看'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    intro.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_source.isNotEmpty)
                  Text(
                    _source,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              intro.abstract.isNotEmpty ? intro.abstract : '暂无介绍',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    _openUrl(intro.url.isNotEmpty ? intro.url : _baikeUrl),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('查看百科词条'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendList(ThemeData theme, List<CourseRecommend> list) {
    if (list.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('暂无匹配的推荐教程', style: theme.textTheme.bodySmall),
        ),
      );
    }
    return Column(
      children: list.map((CourseRecommend item) {
        final isMooc =
            item.source.contains('MOOC') || item.source.contains('高教');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openUrl(item.url),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(child: Text(isMooc ? 'M' : 'B')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.title, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 2),
                        Text(
                          item.source,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('无法打开链接：$url')));
    }
  }
}
