import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/course_recommend.dart';

/// 课程直达链接库
///
/// 数据由脚本逐条访问验证后生成（assets/course_db/links.json）：
/// - mooc：中国大学 MOOC 的具体课程页
/// - bili：B 站的具体视频页
class CourseLinkDb {
  CourseLinkDb._();

  static final CourseLinkDb instance = CourseLinkDb._();

  static const String _assetPath = 'assets/course_db/links.json';

  final Map<String, List<CourseRecommend>> _map =
      <String, List<CourseRecommend>>{};

  bool get isLoaded => _map.isNotEmpty;

  int get count => _map.length;

  Future<void> load() async {
    if (_map.isNotEmpty) return;
    try {
      final String raw = await rootBundle.loadString(_assetPath);
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      data.forEach((String name, dynamic value) {
        if (value is! Map<String, dynamic>) return;
        final List<CourseRecommend> list = <CourseRecommend>[];
        list.addAll(_parseMooc(value['mooc']));
        list.addAll(_parseBili(value['bili']));
        if (list.isNotEmpty) _map[name] = list;
      });
    } catch (error) {
      assert(() {
        // ignore: avoid_print
        print('课程链接库加载失败: $error');
        return true;
      }());
    }
  }

  List<CourseRecommend> _parseMooc(dynamic raw) {
    final List<CourseRecommend> list = <CourseRecommend>[];
    for (final dynamic item in _asList(raw)) {
      final Map<String, dynamic> map = item as Map<String, dynamic>;
      final String title = map['title'] as String? ?? '';
      final String school = map['school'] as String? ?? '';
      final String url = map['url'] as String? ?? '';
      if (url.isEmpty) continue;
      list.add(
        CourseRecommend(
          title: title.isEmpty ? '中国大学 MOOC 课程' : title,
          source: school.isEmpty ? '中国大学 MOOC' : '中国大学 MOOC · $school',
          url: url,
        ),
      );
    }
    return list;
  }

  List<CourseRecommend> _parseBili(dynamic raw) {
    final List<CourseRecommend> list = <CourseRecommend>[];
    for (final dynamic item in _asList(raw)) {
      final Map<String, dynamic> map = item as Map<String, dynamic>;
      final String title = map['title'] as String? ?? '';
      final String author = map['author'] as String? ?? '';
      final String url = map['url'] as String? ?? '';
      if (url.isEmpty) continue;
      list.add(
        CourseRecommend(
          title: title.isEmpty ? 'B 站视频' : title,
          source: author.isEmpty ? 'B 站' : 'B 站 · $author',
          url: url,
        ),
      );
    }
    return list;
  }

  /// 单项时 JSON 可能是对象而非数组，统一转成列表
  List<dynamic> _asList(dynamic raw) {
    if (raw is List<dynamic>) return raw;
    if (raw is Map<String, dynamic>) return <dynamic>[raw];
    return <dynamic>[];
  }

  List<CourseRecommend>? find(String courseName) {
    final String name = courseName.trim();
    if (name.isEmpty) return null;
    if (_map.containsKey(name)) return _map[name];
    for (final String key in _map.keys) {
      if (name.contains(key) || key.contains(name)) return _map[key];
    }
    return null;
  }
}
