import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sub2api_monitor/main.dart';

void main() {
  testWidgets('应用正常启动', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: Sub2ApiMonitorApp()));
    await tester.pumpAndSettle();
  });
}
