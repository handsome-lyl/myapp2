import '../models/course_recommend.dart';
import 'course_link_db.dart';

/// 课程名清洗：去掉末尾的 A/B/Ⅰ/Ⅱ/数字等后缀
String _normalize(String name) {
  return name
      .replaceAll(RegExp(r'[ABC]\s*$'), '')
      .replaceAll(RegExp(r'[ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ]\s*$'), '')
      .replaceAll(RegExp(r'[0-9]+\s*$'), '')
      .trim();
}

String _biliSearch(String name) =>
    'https://search.bilibili.com/all?keyword=${Uri.encodeComponent('$name 教程')}&order=click';

/// 具体课程/视频链接映射
///
/// 表中的慕课链接与 B 站视频链接均为逐个访问验证过的真实页面
/// （无效的 icourse163 课程 ID 会被重定向回首页，故未列入）。
/// 课程列表会随开课轮次变化，个别链接可能失效，届时用兜底的搜索页即可。
final Map<String, List<CourseRecommend>> _staticMap =
    <String, List<CourseRecommend>>{
      '高等数学': <CourseRecommend>[
        const CourseRecommend(
          title: '微积分（一）',
          source: '中国大学 MOOC · 哈尔滨工业大学',
          url: 'https://www.icourse163.org/course/HIT-153001',
        ),
        const CourseRecommend(
          title: '高等数学习题课（二）',
          source: '中国大学 MOOC · 哈尔滨工业大学',
          url: 'https://www.icourse163.org/course/HIT-1001572001',
        ),
        const CourseRecommend(
          title: '高等数学',
          source: 'B 站 · 快乐六月一',
          url: 'https://www.bilibili.com/video/BV17WytziEuw',
        ),
        const CourseRecommend(
          title: '高等数学（下）6 小时速成',
          source: 'B 站 · 框框老师课堂',
          url: 'https://www.bilibili.com/video/BV1Hu411s7J1',
        ),
      ],
      '线性代数': <CourseRecommend>[
        const CourseRecommend(
          title: '线性代数',
          source: '中国大学 MOOC · 郑州大学',
          url: 'https://www.icourse163.org/course/ZZU-1207207802',
        ),
        const CourseRecommend(
          title: '线性代数与空间解析几何',
          source: '中国大学 MOOC · 哈尔滨工业大学',
          url: 'https://www.icourse163.org/course/HTT-1002117005',
        ),
        const CourseRecommend(
          title: '线性代数教学视频',
          source: 'B 站 · 吉林大学',
          url: 'https://www.bilibili.com/video/BV1C7411c7J3',
        ),
        const CourseRecommend(
          title: '张宇数学 · 线性代数基础 30 讲',
          source: 'B 站 · 小迪不摸鱼',
          url: 'https://www.bilibili.com/video/BV1uxyJzAEe6',
        ),
      ],
      '概率论': <CourseRecommend>[
        const CourseRecommend(
          title: '概率论与数理统计',
          source: '中国大学 MOOC · 哈尔滨工业大学',
          url: 'https://www.icourse163.org/course/HIT-20021',
        ),
        const CourseRecommend(
          title: '概率论与数理统计 13 小时系统学习',
          source: 'B 站 · 蜂考',
          url: 'https://www.bilibili.com/video/BV1GJN8egEGN',
        ),
        const CourseRecommend(
          title: '概率论与数理统计',
          source: 'B 站 · 哈尔滨工业大学',
          url: 'https://www.bilibili.com/video/BV1us411J7ZA',
        ),
      ],
      '离散数学': <CourseRecommend>[
        const CourseRecommend(
          title: '离散数学',
          source: '中国大学 MOOC · 华南理工大学',
          url: 'https://www.icourse163.org/course/SCUT-1206350803',
        ),
        const CourseRecommend(
          title: '离散数学',
          source: '中国大学 MOOC · 慕课精选',
          url: 'https://www.icourse163.org/course/detail.htm?cid=1450160201',
        ),
        const CourseRecommend(
          title: '离散数学（全 33 讲）国家级精品课',
          source: 'B 站 · 厦门大学',
          url: 'https://www.bilibili.com/video/BV19KymzSE3c',
        ),
        const CourseRecommend(
          title: '离散数学 5 小时期末突击',
          source: 'B 站 · 蜂考',
          url: 'https://www.bilibili.com/video/BV1jTCNYdEoV',
        ),
      ],
      '数据结构': <CourseRecommend>[
        const CourseRecommend(
          title: '数据结构',
          source: '中国大学 MOOC · 西北大学',
          url: 'https://www.icourse163.org/course/NWU-298002',
        ),
        const CourseRecommend(
          title: '数据结构',
          source: '中国大学 MOOC · 浙江大学',
          url: 'https://www.icourse163.org/course/ZJU-93001',
        ),
        const CourseRecommend(
          title: '数据结构（C 语言描述）',
          source: 'B 站 · 逊哥带你学计算机',
          url: 'https://www.bilibili.com/video/BV1tNpbekEht',
        ),
        const CourseRecommend(
          title: '数据结构 · 李春葆',
          source: 'B 站 · 爱喝粥的苗',
          url: 'https://www.bilibili.com/video/BV1rt411J7VN',
        ),
      ],
      '操作系统': <CourseRecommend>[
        const CourseRecommend(
          title: '计算机操作系统',
          source: '中国大学 MOOC · 南京大学',
          url: 'https://www.icourse163.org/course/NJU-1001571004',
        ),
        const CourseRecommend(
          title: '操作系统',
          source: '中国大学 MOOC · 慕课精选',
          url: 'https://www.icourse163.org/course/detail.htm?cid=1002531008',
        ),
        const CourseRecommend(
          title: '操作系统零基础入门（全 60 集）',
          source: 'B 站 · 嵌入式-',
          url: 'https://www.bilibili.com/video/BV1wf5J6vECQ',
        ),
        const CourseRecommend(
          title: '操作系统 4 小时期末速成',
          source: 'B 站 · 数学建模老哥',
          url: 'https://www.bilibili.com/video/BV1ju6TYHEKU',
        ),
      ],
      '计算机网络': <CourseRecommend>[
        const CourseRecommend(
          title: '计算机网络',
          source: '中国大学 MOOC · 哈尔滨工业大学',
          url: 'https://www.icourse163.org/course/0809HIT015-154005',
        ),
        const CourseRecommend(
          title: '计算机网络技能实战教程合集',
          source: 'B 站 · 刘金玉编程',
          url: 'https://www.bilibili.com/video/BV1c64y1X7DN',
        ),
        const CourseRecommend(
          title: '计算机编程基础速成课（全 118 集）',
          source: 'B 站 · 成龙学长',
          url: 'https://www.bilibili.com/video/BV1kxyozoE5v',
        ),
      ],
      'C语言': <CourseRecommend>[
        const CourseRecommend(
          title: '程序设计入门——C 语言',
          source: '中国大学 MOOC · 浙江大学 翁恺',
          url: 'https://www.icourse163.org/course/ZJU-199001',
        ),
        const CourseRecommend(
          title: 'C 语言程序设计 · 翁恺',
          source: '中国大学 MOOC · 浙江大学',
          url: 'https://www.icourse163.org/course/detail.htm?cid=121004',
        ),
        const CourseRecommend(
          title: 'C 语言零基础教程（全 198 集）',
          source: 'B 站 · 谁懂啊小程',
          url: 'https://www.bilibili.com/video/BV1c2yWzNEyq',
        ),
        const CourseRecommend(
          title: '尚硅谷 C 语言零基础入门',
          source: 'B 站 · 尚硅谷',
          url: 'https://www.bilibili.com/video/BV1Bh4y1q7Nt',
        ),
      ],
      '大学物理': <CourseRecommend>[
        const CourseRecommend(
          title: '大学物理',
          source: '中国大学 MOOC · 哈尔滨工业大学',
          url: 'https://www.icourse163.org/course/HIT-20017',
        ),
        const CourseRecommend(
          title: '大学物理（东北大学 · 马文蔚）',
          source: 'B 站 · 小考神丨不挂科',
          url: 'https://www.bilibili.com/video/BV1qW411H7UX',
        ),
        const CourseRecommend(
          title: '大学物理（马文蔚版）正课',
          source: 'B 站 · 曹一轩',
          url: 'https://www.bilibili.com/video/BV1AxL3zFEdq',
        ),
      ],
      '机器学习': <CourseRecommend>[
        const CourseRecommend(
          title: '吴恩达机器学习课程（官方中英）',
          source: 'B 站 · 吴恩达AI_AndrewNg',
          url: 'https://www.bilibili.com/video/BV1owrpYKEtP',
        ),
        const CourseRecommend(
          title: '机器学习导论（张旭东教授慕课）',
          source: 'B 站 · 乐学帮',
          url: 'https://www.bilibili.com/video/BV1xD4y1B74A',
        ),
      ],
    };

/// 未收录具体链接的课程：只给 B 站搜索入口
List<CourseRecommend> _generateDynamic(String courseName) {
  return <CourseRecommend>[
    CourseRecommend(
      title: '「$courseName」B 站播放量排序',
      source: 'B 站 · 搜索页',
      url: _biliSearch(courseName),
    ),
    CourseRecommend(
      title: '「$courseName」B 站综合排序',
      source: 'B 站 · 搜索页',
      url:
          'https://search.bilibili.com/all?keyword=${Uri.encodeComponent(courseName)}',
    ),
  ];
}

List<CourseRecommend> findRecommendsFor(String courseName) {
  final normalized = _normalize(courseName);
  // 1. 手工精选（含已验证的 B 站视频）
  if (_staticMap.containsKey(normalized)) return _staticMap[normalized]!;
  for (final String key in _staticMap.keys) {
    if (normalized.contains(key) || key.contains(normalized)) {
      return _staticMap[key]!;
    }
  }
  // 2. 抓取并验证过的直达链接（慕课没有的课程只含 B 站视频）
  final crawled = CourseLinkDb.instance.find(normalized);
  if (crawled != null && crawled.isNotEmpty) return crawled;
  // 3. 兜底：B 站搜索入口
  return _generateDynamic(normalized);
}
