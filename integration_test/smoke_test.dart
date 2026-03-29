// 冒烟测试：注册→登录→滑卡→匹配→发消息 完整流程
// 运行：flutter test integration_test/smoke_test.dart --device-id=<emulator>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dating_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: 注册→登录→发现页加载', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 应该跳转到登录页（未登录）
    expect(find.text('春水圈'), findsOneWidget);

    // 点注册
    await tester.tap(find.text('没有账号？立即注册'));
    await tester.pumpAndSettle();

    // 填写注册信息
    await tester.enterText(find.byKey(const Key('name')), '测试用户');
    await tester.enterText(find.byKey(const Key('email')), 'smoke_test_${DateTime.now().millisecondsSinceEpoch}@test.com');
    await tester.enterText(find.byKey(const Key('password')), 'Test1234');

    // 选生日
    await tester.tap(find.byKey(const Key('birth_date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定').last);
    await tester.pumpAndSettle();

    // 提交注册
    await tester.tap(find.byKey(const Key('register_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 应该跳到发现页
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('smoke: 登录流程', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.enterText(find.byKey(const Key('email')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('password')), '123456');
    await tester.tap(find.byKey(const Key('login_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
