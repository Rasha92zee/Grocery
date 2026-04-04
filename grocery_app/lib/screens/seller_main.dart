//import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';
import 'seller_dashboard_screen.dart';
import 'seller_inventory_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_settings_screen.dart';
import '../services/api_service.dart';


enum SellerTab { dashboard, inventory, orders, settings }

class SellerMainScreen extends StatefulWidget {
  const SellerMainScreen({super.key});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  SellerTab _currentTab = SellerTab.dashboard;
  String _shopName = '';
  String _fullName = '';
  bool _isApproved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Load cached values first for instant display
  setState(() {
    _shopName = prefs.getString('shop_name') ?? 'My Shop';
    _fullName = prefs.getString('full_name') ?? '';
    _isApproved = prefs.getBool('shop_approved') ?? false;
    _isLoading = false;
  });

  // Then re-check live from server in case admin approved since last login
  final shop = await ApiService.fetchMyShop();
  if (shop != null && mounted) {
    final approved = shop['is_active'] ?? false;
    final name = shop['shop_name'] ?? _shopName;
    await prefs.setBool('shop_approved', approved);
    await prefs.setString('shop_name', name);
    setState(() {
      _isApproved = approved;
      _shopName = name;
    });
  }
}

  final List<_DrawerItem> _drawerItems = [
    _DrawerItem(tab: SellerTab.dashboard,  icon: Icons.dashboard_rounded,       label: 'Dashboard'),
    _DrawerItem(tab: SellerTab.inventory,  icon: Icons.inventory_2_rounded,      label: 'My Inventory'),
    _DrawerItem(tab: SellerTab.orders,     icon: Icons.receipt_long_rounded,     label: 'Orders'),
    _DrawerItem(tab: SellerTab.settings,   icon: Icons.store_mall_directory_rounded, label: 'Shop Settings'),
  ];

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)));
    }
    if (!_isApproved) {
      return const SellerPendingApprovalScreen();
    }
    switch (_currentTab) {
      case SellerTab.dashboard:  return const SellerDashboardScreen();
      case SellerTab.inventory:  return const SellerInventoryScreen();
      case SellerTab.orders:     return const SellerOrdersScreen();
      case SellerTab.settings:   return const SellerSettingsScreen();
    }
  }

  String get _currentTitle {
    switch (_currentTab) {
      case SellerTab.dashboard: return 'Dashboard';
      case SellerTab.inventory: return 'My Inventory';
      case SellerTab.orders:    return 'Orders';
      case SellerTab.settings:  return 'Shop Settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color drawerBg = isDark ? const Color(0xFF111111) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _currentTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          // Theme toggle
          GestureDetector(
            onTap: () => themeProvider.toggleTheme(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
              child: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: isDark ? Colors.amber : Colors.indigo,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: drawerBg,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Color(0xFF16A34A), size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _shopName,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fullName,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(height: 10),
                    // Approval badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isApproved
                            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                            : Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isApproved
                              ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                              : Colors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _isApproved ? '✓ Approved' : '⏳ Pending Approval',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isApproved
                              ? const Color(0xFF16A34A)
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Nav items ────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  children: _drawerItems.map((item) {
                    final bool isSelected = _currentTab == item.tab;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentTab = item.tab);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF16A34A)
                                  : textSecondary,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF16A34A)
                                    : textPrimary,
                              ),
                            ),
                            if (isSelected) ...[
                              const Spacer(),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Logout ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: GestureDetector(
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/', (route) => false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 20, color: Colors.redAccent),
                        const SizedBox(width: 14),
                        Text(
                          "Logout",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}

class _DrawerItem {
  final SellerTab tab;
  final IconData icon;
  final String label;
  const _DrawerItem({required this.tab, required this.icon, required this.label});
}

// ── Pending Approval Screen ───────────────────────────────────────────────────

class SellerPendingApprovalScreen extends StatelessWidget {
  const SellerPendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 56, color: Colors.orange),
            ),
            const SizedBox(height: 28),
            Text(
              "Awaiting Approval",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Your shop has been submitted for review. Our team will approve it shortly. You'll be notified once you're live.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Approval usually takes 1–2 business days.",
                      style: GoogleFonts.inter(
                          fontSize: 12, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}