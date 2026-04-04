import 'dart:developer' as dev;
import 'order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final orders = await ApiService.fetchOrders();
    dev.log("fetchOrders: ${orders.length} orders", name: 'OrderHistoryScreen');
    if (mounted) {
      setState(() {
        _orders = orders.where((o) => o.status != 'CANCELLED').toList();
        _isLoading = false;
      });
    }
  }

  // ─── CANCEL ORDER ──────────────────────────────────────────────────────────

  Future<void> _cancelOrder(OrderModel order) async {
    // Optimistic removal
    setState(() => _orders.remove(order));

    final success = await ApiService.cancelOrder(order.id);
    dev.log("cancelOrder ${order.id}: $success", name: 'OrderHistoryScreen');

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order #${order.id} cancelled"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      // Rollback
      setState(() => _orders.insert(0, order));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not cancel — order may already be packed"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmCancel(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        final bool isDark = themeProvider.themeMode == ThemeMode.dark;
        final Color bg =
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
        final Color textPrimary = isDark ? Colors.white : Colors.black87;
        final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),

              Text(
                "Cancel Order?",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Order #${order.id} from ${order.shopName} will be cancelled. This cannot be undone.",
                style: GoogleFonts.inter(
                    fontSize: 13, color: textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  // Keep order
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: Center(
                          child: Text("Keep Order",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _cancelOrder(order);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text("Cancel Order",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    final Color cardBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF16A34A)));
    }

    if (_orders.isEmpty) {
      return _buildEmptyState(isDark, textSecondary);
    }

    return RefreshIndicator(
      color: const Color(0xFF16A34A),
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final bool canCancel = order.status == 'PENDING';

          // ✅ Swipe left to reveal cancel — only for PENDING orders
          return Dismissible(
            key: ValueKey('order-${order.id}'),
            direction: canCancel
                ? DismissDirection.endToStart
                : DismissDirection.none,
            confirmDismiss: (_) async {
              _confirmCancel(order);
              return false; // We handle removal ourselves
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text("Cancel",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            child: _buildOrderCard(
                order, isDark, cardBg, textPrimary, textSecondary),
          );
        },
      ),
    );
  }

  // ─── ORDER CARD ─────────────────────────────────────────────────────────────

  Widget _buildOrderCard(
    OrderModel order,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: EdgeInsets.zero,
          onExpansionChanged: (_) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Color(0xFF16A34A), size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  order.shopName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(order.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.createdAt),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: textSecondary),
                ),
                Text(
                  "₹${order.totalPrice.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Divider(
                color: isDark ? Colors.white12 : Colors.black12, height: 1),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            "${item.quantity}×",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "₹${(item.priceAtOrder * item.quantity).toStringAsFixed(0)}",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                )),

            // Cancel button inside expanded — only for PENDING
            if (order.status == 'PENDING')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: GestureDetector(
                  onTap: () => _confirmCancel(order),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        "Cancel Order",
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── STATUS BADGE ───────────────────────────────────────────────────────────

  Widget _statusBadge(String status) {
    final Map<String, Map<String, dynamic>> config = {
      'PENDING': {'color': const Color(0xFFf59e0b), 'label': 'Pending'},
      'PACKING': {'color': const Color(0xFF3b82f6), 'label': 'Packing'},
      'READY': {'color': const Color(0xFF8b5cf6), 'label': 'Ready'},
      'COMPLETED': {'color': const Color(0xFF16A34A), 'label': 'Completed'},
      'CANCELLED': {'color': Colors.redAccent, 'label': 'Cancelled'},
    };

    final cfg = config[status] ?? {'color': Colors.grey, 'label': status};
    final Color color = cfg['color'] as Color;
    final String label = cfg['label'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${date.day} ${months[date.month - 1]}, ${date.year}";
  }

  Widget _buildEmptyState(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72,
              color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 20),
          Text(
            "No orders yet",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your order history will appear here",
            style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }
}