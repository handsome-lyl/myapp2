import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_entry.dart';
import '../services/course_db.dart';
import 'course_detail_page.dart';

const String _storageKey = 'courses_list';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 默认课程，本地存储为空时展示
  final List<String> _courses = <String>['高等数学'];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);
    if (!mounted) return;
    if (stored != null && stored.isNotEmpty) {
      setState(() {
        _courses
          ..clear()
          ..addAll(stored);
      });
    }
    setState(() => _loaded = true);
  }

  Future<void> _saveCourses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _courses);
  }

  Future<void> _addCourseDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        // 输入联想结果，随输入实时更新
        List<CourseEntry> suggestions = const <CourseEntry>[];
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('添加课程'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '输入课程名称，如 数据结构',
                      ),
                      onChanged: (String value) {
                        setDialogState(() {
                          suggestions = CourseDb.instance.suggest(value);
                        });
                      },
                      onSubmitted: (String value) =>
                          Navigator.of(context).pop(value.trim()),
                    ),
                    if (suggestions.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: suggestions.length,
                          itemBuilder: (BuildContext context, int index) {
                            final CourseEntry item = suggestions[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.menu_book_outlined),
                              title: Text(item.name),
                              subtitle: Text('${item.category} · ${item.type}'),
                              onTap: () => Navigator.of(context).pop(item.name),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
    if (name == null || name.isEmpty) return;
    // 去重，防止输入已有的课程
    if (_courses.contains(name)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('「$name」已在列表中')));
      return;
    }
    setState(() => _courses.add(name));
    await _saveCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的培养方案')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final course = _courses[index];
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            CourseDetailPage(courseName: course),
                      ),
                    );
                  },
                  child: Text(course),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
