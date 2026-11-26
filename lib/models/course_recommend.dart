class CourseRecommend {
  const CourseRecommend({
    required this.title,
    required this.source,
    required this.url,
  });

  final String title;
  final String source; // "MOOC" | "B 站"
  final String url;
}

class BaikeCourseIntro {
  const BaikeCourseIntro({
    required this.title,
    required this.description,
    required this.abstract,
    required this.url,
  });

  final String title;
  final String description;
  final String abstract;
  final String url;
}
