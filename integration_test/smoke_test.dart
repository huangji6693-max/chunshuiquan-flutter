// 结构性冒烟测试：确保登录/注册关键页面元素存在
// 运行：flutter test integration_test/smoke_test.dart --device-id=<emulator>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chunshuiquan_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: 默认进入登录页', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('春水圈'), findsOneWidget);
    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.byKey(const Key('password')), findsOneWidget);
    expect(find.byKey(const Key('login_btn')), findsOneWidget);
  });

  testWidgets('smoke: 可进入注册页并看到关键字段', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text('立即注册'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('name')), findsOneWidget);
    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.byKey(const Key('password')), findsOneWidget);
    expect(find.byKey(const Key('birth_date')), findsOneWidget);
    expect(find.byKey(const Key('register_btn')), findsOneWidget);
  });
}
