import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';
import '../models/cart_item_model.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'ALL';

  final List<String> _statuses = ['ALL', 'PENDING', 'PACKING', 'READY', 'COMPLETED'];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final orders = await ApiService.fetchOrders();
    dev.log("sellerOrders: ${orders.length}", name: 'SellerOrdersScreen');
    if (mounted) setState(() { _orders = orders; _isLoading = false; });
  }

  List<OrderModel> get _filtered => _filterStatus == 'ALL'
      ? _orders
      : _orders.where((o) => o.status == _filterStatus).toList();

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService.updateOrderStatus(order.id, newStatus);
    dev.log("updateStatus ${order.id} -> $newStatus: $success", name: 'SellerOrdersScreen');
    if (success) {
      await _fetchOrders();
      messenger.showSnackBar(SnackBar(
        content: Text("Order #${order.id} → $newStatus"),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text("Failed to update order")));
    }
  }

  void _showStatusPicker(OrderModel order) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color textPrimary = isDark ? Colors.white : Colors.black87;

    const nextStatus = {
      'PENDING': 'PACKING',
      'PACKING': 'READY',
      'READY': 'COMPLETED',
    };

    final next = nextStatus[order.status];
    if (next == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Update Order #${order.id}",
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 6),
            Text("${order.items.length} items · ₹${order.totalPrice.toStringAsFixed(0)}",
                style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () { Navigator.pop(ctx); _updateStatus(order, next); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text("Mark as $next",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)));

    return Column(
      children: [
        // ── Filter tabs ───────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: _statuses.map((s) {
              final bool selected = _filterStatus == s;
              // Status dot colors
              final Map<String, Color> dotColors = {
                'ALL': const Color(0xFF16A34A),
                'PENDING': const Color(0xFFf59e0b),
                'PACKING': const Color(0xFF3b82f6),
                'READY': const Color(0xFF8b5cf6),
                'COMPLETED': const Color(0xFF16A34A),
              };
              final Color dotColor = dotColors[s] ?? const Color(0xFF16A34A);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filterStatus = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: selected && !isDark ? [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4, offset: const Offset(0, 1))
                      ] : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          Container(
                            width: 5, height: 5,
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                                color: dotColor, shape: BoxShape.circle),
                          ),
                        Text(
                          s == 'COMPLETED' ? 'DONE' : s,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            color: selected ? dotColor : textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Text("No $_filterStatus orders",
                  style: GoogleFonts.inter(color: textSecondary, fontSize: 14)))
              : RefreshIndicator(
                  color: const Color(0xFF16A34A),
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final order = _filtered[i];
                      final Map<String, Color> statusColors = {
                        'PENDING': const Color(0xFFf59e0b),
                        'PACKING': const Color(0xFF3b82f6),
                        'READY': const Color(0xFF8b5cf6),
                        'COMPLETED': const Color(0xFF16A34A),
                        'CANCELLED': Colors.redAccent,
                      };
                      final color = statusColors[order.status] ?? Colors.grey;
                      final bool canAdvance = ['PENDING','PACKING','READY'].contains(order.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            childrenPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt_long_rounded, color: color, size: 20),
                            ),
                            title: Row(children: [
                              Expanded(child: Text("Order #${order.id}",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary))),
                              _badge(order.status, color),
                            ]),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text("${order.items.length} items · ₹${order.totalPrice.toStringAsFixed(0)}",
                                  style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                            ),
                            children: [
                              Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                              ...order.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(children: [
                                  Text("${item.quantity}×",
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12,
                                          color: const Color(0xFF16A34A))),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item.productName,
                                      style: GoogleFonts.inter(fontSize: 13, color: textPrimary))),
                                  Text("₹${(item.priceAtOrder * item.quantity).toStringAsFixed(0)}",
                                      style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
                                ]),
                              )),
                              // ── Fulfillment info ──────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: order.fulfillmentType == 'DELIVERY'
                                        ? const Color(0xFF3b82f6).withValues(alpha: 0.08)
                                        : const Color(0xFF16A34A).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: order.fulfillmentType == 'DELIVERY'
                                          ? const Color(0xFF3b82f6).withValues(alpha: 0.3)
                                          : const Color(0xFF16A34A).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(
                                          order.fulfillmentType == 'DELIVERY'
                                              ? Icons.delivery_dining_rounded
                                              : Icons.storefront_rounded,
                                          size: 14,
                                          color: order.fulfillmentType == 'DELIVERY'
                                              ? const Color(0xFF3b82f6)
                                              : const Color(0xFF16A34A),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          order.fulfillmentType == 'DELIVERY' ? 'Delivery' : 'Pickup',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold, fontSize: 12,
                                            color: order.fulfillmentType == 'DELIVERY'
                                                ? const Color(0xFF3b82f6)
                                                : const Color(0xFF16A34A),
                                          ),
                                        ),
                                      ]),
                                      if (order.fulfillmentType == 'DELIVERY' && order.deliveryAddress.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(order.deliveryAddress,
                                            style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                                      ],
                                      if (order.fulfillmentType == 'PICKUP' && order.pickupSlot.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text('Slot: ${order.pickupSlot}',
                                            style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              // ── Navigate button for delivery ───────────────
                              if (order.fulfillmentType == 'DELIVERY' && order.deliveryAddress.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final encoded = Uri.encodeComponent(order.deliveryAddress);
                                      final url = Uri.parse(
                                          'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3b82f6).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF3b82f6).withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.directions_rounded,
                                              color: Color(0xFF3b82f6), size: 16),
                                          const SizedBox(width: 6),
                                          Text("Navigate to customer",
                                              style: GoogleFonts.inter(
                                                  color: const Color(0xFF3b82f6),
                                                  fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (canAdvance)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                                  child: GestureDetector(
                                    onTap: () => _showStatusPicker(order),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16A34A),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(child: Text("Update Status",
                                          style: GoogleFonts.inter(color: Colors.white,
                                              fontWeight: FontWeight.bold, fontSize: 13))),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _badge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );
}