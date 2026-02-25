import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/product_listing/product_listing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider(api: apiClient)),
        ChangeNotifierProvider(create: (_) => AuthProvider(api: apiClient)),
      ],
      child: const EcomDemoApp(),
    ),
  );
}

class EcomDemoApp extends StatelessWidget {
  const EcomDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecom Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ProductListingScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
