import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'providers/location_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const BerryBasketApp(),
    ),
  );
}

class BerryBasketApp extends StatelessWidget {
  const BerryBasketApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Berry Basket',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      // Keeps all three areas (AppBar, body, BottomNav) in sync
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      home: const LoginScreen(),
    );
  }
}
