import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_net_lab/main.dart';

void main() {
  testWidgets('首页展示第 11 章功能模块', (WidgetTester tester) async {
    await tester.pumpWidget(const NetLabApp());

    expect(find.text('文件与网络实验室'), findsOneWidget);
    expect(find.text('文件操作'), findsOneWidget);
    expect(find.text('Socket API'), findsOneWidget);
    expect(find.text('11.4'), findsOneWidget);
  });
}
