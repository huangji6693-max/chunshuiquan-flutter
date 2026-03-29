import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dating_app/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChunShuiQuanApp()));
    await tester.pump();
    // App 能启动不崩溃
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
