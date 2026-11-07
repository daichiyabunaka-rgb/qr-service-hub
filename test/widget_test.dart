import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_service_hub/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen が表示され、ログインフォームと登録切替がある', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('メールアドレス'), findsOneWidget);
    expect(find.text('パスワード'), findsOneWidget);
    expect(find.text('アカウントを作成する'), findsOneWidget);

    // 新規登録モードへの切替
    await tester.tap(find.text('アカウントを作成する'));
    await tester.pumpAndSettle();
    expect(find.text('新規登録'), findsOneWidget);
  });
}
