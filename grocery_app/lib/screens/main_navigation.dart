import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'order_history_screen.dart';
import 'shops_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MasterProductGrid(),
    const FavoritesScreen(),
    const CartScreen(),
    const OrderHistoryScreen(),
    const ShopsScreen(),
  ];

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Berry Basket";
      case 1:
        return "Saved Items";
      case 2:
        return "My Cart";
      case 3:
        return "Order History";
      case 4:
        return "Our Shops";
      default:
        return "Berry Basket";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    // Single source of truth for background color across all three areas
    final Color scaffoldBg = isDark
        ? const Color(0xFF1A1A1A)   // dark: deep neutral
        : const Color(0xFFFBF8F3);  // light: warm cream/beige white

    final Color navBarBg = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFBF8F3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: scaffoldBg,
      child: Scaffold(
        // Make Scaffold itself transparent so AnimatedContainer controls the bg
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          // Explicitly set to same color — NOT transparent
          backgroundColor: scaffoldBg,
          centerTitle: true,
          title: Text(
            _getAppBarTitle(),
            style: GoogleFonts.cookie(
              fontSize: 32,
              color: const Color(0xFF16A34A),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  return RotationTransition(
                    turns: animation,
                    child: ScaleTransition(
                        scale: animation, child: child),
                  );
                },
                child: Icon(
                  isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  key: ValueKey<bool>(isDark),
                  color: isDark ? Colors.amber : Colors.indigo,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) =>
              setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          // Explicitly same color as AppBar and scaffold
          backgroundColor: navBarBg,
          elevation: 0,
          selectedItemColor: const Color(0xFF16A34A),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded), label: 'Shop'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite_rounded), label: 'Saved'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded), label: 'Cart'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.storefront_rounded), label: 'Shops'),
          ],
        ),
      ),
    );
  }
}