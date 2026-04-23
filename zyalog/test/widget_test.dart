import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zyalog/src/app.dart';

void main() {
  testWidgets('App renders initial loading state', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZyaLogApp()));

    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
