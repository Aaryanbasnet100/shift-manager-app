import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/i18n/strings.dart';
import 'package:flutter_application_1/widgets/neon_stat_card.dart';
import 'package:flutter_application_1/widgets/neon_widgets.dart';

void main() {
  testWidgets('NeonStatCard counts up to its value', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: NeonStatCard(label: 'TEST', value: 42, icon: Icons.star))));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
    expect(find.text('TEST'), findsOneWidget);
  });

  testWidgets('LanguageToggle switches appLang and highlights selection', (tester) async {
    appLang.value = 'en';
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LanguageToggle())));
    await tester.tap(find.text('DE'));
    await tester.pumpAndSettle();
    expect(appLang.value, 'de');
    expect(t('vacation'), 'Urlaub');
    appLang.value = 'en';
  });

  testWidgets('EmptyState renders message and wave logo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(message: 'nothing here'))));
    expect(find.text('nothing here'), findsOneWidget);
    expect(find.byIcon(Icons.waves_rounded), findsOneWidget);
  });
}
