import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';
import '../models/cart_item_model.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  List<OrderModel> _recentOrders = [];
  bool _isLoading = true;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  double _totalRevenue = 0;
  int _completedOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final orders = await ApiService.fetchOrders();
    dev.log("seller dashboard: ${orders.length} orders", name: 'SellerDashboard');
    if (mounted) {
      setState(() {
        _recentOrders = orders.take(5).toList();
        _totalOrders = orders.length;
        _pendingOrders = orders.where((o) => o.status == 'PENDING').length;
        _completedOrders = orders.where((o) => o.status == 'COMPLETED').length;
        _totalRevenue = orders
            .where((o) => o.status == 'COMPLETED')
            .fold(0, (sum, o) => sum + o.totalPrice);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)));
    }

    return RefreshIndicator(
      color: const Color(0xFF16A34A),
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // ── Stats grid ────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard("Total Orders", "$_totalOrders",
                  Icons.receipt_long_rounded, const Color(0xFF16A34A), isDark, cardBg, textPrimary, textSecondary),
              _statCard("Pending", "$_pendingOrders",
                  Icons.hourglass_top_rounded, const Color(0xFFf59e0b), isDark, cardBg, textPrimary, textSecondary),
              _statCard("Completed", "$_completedOrders",
                  Icons.check_circle_outline_rounded, const Color(0xFF3b82f6), isDark, cardBg, textPrimary, textSecondary),
              _statCard("Revenue", "₹${_totalRevenue.toStringAsFixed(0)}",
                  Icons.currency_rupee_rounded, const Color(0xFF8b5cf6), isDark, cardBg, textPrimary, textSecondary),
            ],
          ),

          const SizedBox(height: 28),

          // ── Recent orders ──────────────────────────────────────────
          Text("Recent Orders",
              style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),

          if (_recentOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Center(
                child: Text("No orders yet",
                    style: GoogleFonts.inter(color: textSecondary, fontSize: 14)),
              ),
            )
          else
            ..._recentOrders.map((order) =>
                _recentOrderRow(order, isDark, cardBg, textPrimary, textSecondary)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color,
      bool isDark, Color cardBg, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  )),
              Text(label,
                  style: GoogleFonts.inter(fontSize: 11, color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentOrderRow(OrderModel order, bool isDark, Color cardBg,
      Color textPrimary, Color textSecondary) {
    final Map<String, Color> statusColors = {
      'PENDING': const Color(0xFFf59e0b),
      'PACKING': const Color(0xFF3b82f6),
      'READY': const Color(0xFF8b5cf6),
      'COMPLETED': const Color(0xFF16A34A),
      'CANCELLED': Colors.redAccent,
    };
    final color = statusColors[order.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Color(0xFF16A34A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order #${order.id}",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: textPrimary)),
                Text("${order.items.length} items · ₹${order.totalPrice.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              order.status,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}