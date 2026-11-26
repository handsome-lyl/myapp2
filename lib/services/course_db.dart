import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/course_entry.dart';

/// 内置课程库：启动时从 assets 读取 JSON，提供课程查找与联想
class CourseDb {
  CourseDb._();

  static final CourseDb instance = CourseDb._();

  /// 课程库资源文件（按学科门类拆分，便于维护）
  static const List<String> _assetPaths = <String>[
    'assets/course_db/social.json',
    'assets/course_db/science.json',
    'assets/course_db/engineering_a.json',
    'assets/course_db/engineering_b.json',
    'assets/course_db/agri_med_mgmt_art.json',
  ];

  final List<CourseEntry> _entries = <CourseEntry>[];
  bool _loaded = false;

  /// 课程总数
  int get count => _entries.length;

  bool get isLoaded => _loaded;

  /// 加载全部课程数据（应用启动时调用一次）
  Future<void> load() async {
    if (_loaded) return;
    for (final String path in _assetPaths) {
      try {
        final String raw = await rootBundle.loadString(path);
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        final String discipline = data['discipline'] as String? ?? '';
        final List<dynamic> categories =
            data['categories'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic categoryRaw in categories) {
          final Map<String, dynamic> category =
              categoryRaw as Map<String, dynamic>;
          final String categoryName = category['name'] as String? ?? '';
          final List<dynamic> courses =
              category['courses'] as List<dynamic>? ?? <dynamic>[];
          for (final dynamic courseRaw in courses) {
            _entries.add(
              CourseEntry.fromJson(
                courseRaw as Map<String, dynamic>,
                discipline: discipline,
                category: categoryName,
              ),
            );
          }
        }
      } catch (error) {
        // 单个资源文件损坏不影响其他文件加载
        assert(() {
          // ignore: avoid_print
          print('课程库加载失败 $path: $error');
          return true;
        }());
      }
    }
    _loaded = true;
  }

  /// 按课程名查找：先精确匹配，再模糊包含匹配
  CourseEntry? find(String courseName) {
    final String name = courseName.trim();
    if (name.isEmpty) return null;
    for (final CourseEntry entry in _entries) {
      if (entry.name == name) return entry;
    }
    for (final CourseEntry entry in _entries) {
      if (entry.name.contains(name) || name.contains(entry.name)) {
        return entry;
      }
    }
    return null;
  }

  /// 输入联想：返回名称包含关键字的课程
  List<CourseEntry> suggest(String keyword, {int limit = 8}) {
    final String key = keyword.trim();
    if (key.isEmpty) return const <CourseEntry>[];
    final List<CourseEntry> startsWith = <CourseEntry>[];
    final List<CourseEntry> contains = <CourseEntry>[];
    for (final CourseEntry entry in _entries) {
      if (entry.name == key) continue;
      if (entry.name.startsWith(key)) {
        startsWith.add(entry);
      } else if (entry.name.contains(key) || entry.category.contains(key)) {
        contains.add(entry);
      }
    }
    return <CourseEntry>[...startsWith, ...contains].take(limit).toList();
  }
}
