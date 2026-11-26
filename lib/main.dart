import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/course_db.dart';
import 'services/course_link_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 启动前加载内置课程库与直达链接库，避免首屏读取资源时闪烁
  await CourseDb.instance.load();
  await CourseLinkDb.instance.load();
  runApp(const NetLabApp());
}

class NetLabApp extends StatelessWidget {
  const NetLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '文件与网络实验室',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
