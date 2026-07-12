import 'package:fitai/screens/treinos/ready_plans/widgets/ready_plans_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('encaminha a busca e permite limpar o termo', (tester) async {
    final values = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReadyPlansSearch(onChanged: values.add)),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hipertrofia');
    await tester.pump();
    expect(values.last, 'hipertrofia');

    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pump();
    expect(values.last, isEmpty);
  });
}
