/// 内置课程库中的一条课程记录
class CourseEntry {
  const CourseEntry({
    required this.name,
    required this.discipline,
    required this.category,
    required this.type,
    required this.description,
  });

  /// 课程名称，如「数据结构」
  final String name;

  /// 学科门类，如「工学」
  final String discipline;

  /// 专业类，如「计算机类」
  final String category;

  /// 课程类型：核心 / 专业选修
  final String type;

  /// 课程简介
  final String description;

  /// 从 JSON 对象构建
  factory CourseEntry.fromJson(
    Map<String, dynamic> json, {
    required String discipline,
    required String category,
  }) {
    return CourseEntry(
      name: json['n'] as String? ?? '',
      discipline: discipline,
      category: category,
      type: json['t'] as String? ?? '核心',
      description: json['d'] as String? ?? '',
    );
  }
}
