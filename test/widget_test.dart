import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecom_demo/main.dart';
import 'package:ecom_demo/core/api/api_client.dart';
import 'package:ecom_demo/providers/product_provider.dart';
import 'package:ecom_demo/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test — product listing screen renders', (
    WidgetTester tester,
  ) async {
    final apiClient = ApiClient();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ProductProvider(api: apiClient),
          ),
          ChangeNotifierProvider(create: (_) => AuthProvider(api: apiClient)),
        ],
        child: const EcomDemoApp(),
      ),
    );

    // Verify the product listing screen loads
    expect(find.text('Search products...'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
  });
}
