import 'package:flutter_test/flutter_test.dart';
import 'package:sumup_example/main.dart';

void main() {
  testWidgets('renders the SumUp actions', (tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('Sumup plugin'), findsOneWidget);
    expect(find.text('Init'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Checkout (card reader)'), findsOneWidget);
  });
}
