import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';

enum FulfillmentType { delivery, pickup }

class ShopFulfillment {
  FulfillmentType type;
  String deliveryAddress;
  String pickupSlot;

  ShopFulfillment({
    this.type = FulfillmentType.delivery,
    this.deliveryAddress = '',
    this.pickupSlot = 'Morning (9am–12pm)',
  });
}

class OrderConfirmationScreen extends StatefulWidget {
  final List<CartGroup> groups;
  final double grandTotal;

  const OrderConfirmationScreen({
    super.key,
    required this.groups,
    required this.grandTotal,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isPlacing = false;

  // One fulfillment choice per shop group
  late final Map<String, ShopFulfillment> _fulfillments;
  late final Map<String, TextEditingController> _addressControllers;

  final List<String> _pickupSlots = [
    'Morning (9am–12pm)',
    'Afternoon (12pm–4pm)',
    'Evening (4pm–8pm)',
  ];

  @override
  void initState() {
    super.initState();
    _fulfillments = {
      for (final g in widget.groups) g.shopName: ShopFulfillment(),
    };
    _addressControllers = {
      for (final g in widget.groups)
        g.shopName: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _addressControllers.values) { c.dispose();}
    super.dispose();
  }

  bool get _canPlace {
    // Delivery orders need an address
    for (final entry in _fulfillments.entries) {
      final f = entry.value;
      if (f.type == FulfillmentType.delivery &&
          (_addressControllers[entry.key]?.text.trim().isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _placeOrders() async {
    // Sync address text into fulfillment objects
    for (final entry in _addressControllers.entries) {
      _fulfillments[entry.key]?.deliveryAddress = entry.value.text.trim();
    }

    setState(() => _isPlacing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await ApiService.checkout(
      fulfillments: _fulfillments,
    );

    dev.log("placeOrders: $success", name: 'OrderConfirmation');
    if (!mounted) return;
    setState(() => _isPlacing = false);

    if (success) {
      Provider.of<CartProvider>(context, listen: false).clearCart();
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: const Text("Orders placed successfully! 🎉"),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text("Something went wrong. Please try again."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color bg =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Review Order",
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, color: textPrimary, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  "You're ordering from ${widget.groups.length} shop${widget.groups.length == 1 ? '' : 's'}",
                  style:
                      GoogleFonts.inter(fontSize: 14, color: textSecondary),
                ),
                const SizedBox(height: 20),

                ...widget.groups.map((group) => _buildShopCard(
                    group, isDark, textPrimary, textSecondary)),

                const SizedBox(height: 8),

                // Grand total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF16A34A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF16A34A)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total to pay",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary)),
                      Text(
                        "₹${widget.grandTotal.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Each shop will receive a separate order.",
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Place order button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                  top: BorderSide(
                      color:
                          isDark ? Colors.white12 : Colors.black12)),
            ),
            child: GestureDetector(
              onTap: (_isPlacing || !_canPlace) ? null : _placeOrders,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: (_isPlacing || !_canPlace)
                      ? const Color(0xFF16A34A).withValues(alpha: 0.5)
                      : const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: (_isPlacing || !_canPlace)
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: _isPlacing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          !_canPlace
                              ? "Enter delivery address to continue"
                              : "Place Order  ₹${widget.grandTotal.toStringAsFixed(0)}",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHOP CARD ──────────────────────────────────────────────────────────────

  Widget _buildShopCard(CartGroup group, bool isDark,
      Color textPrimary, Color textSecondary) {
    final Color cardBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final fulfillment = _fulfillments[group.shopName]!;
    final addressCtrl = _addressControllers[group.shopName]!;
    final bool isDelivery =
        fulfillment.type == FulfillmentType.delivery;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop name
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Text(group.shopName,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textPrimary)),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          ...group.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${item.productName} × ${item.quantity}",
                        style: GoogleFonts.inter(
                            fontSize: 13, color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "₹${item.lineTotal.toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A)),
                    ),
                  ],
                ),
              )),

          Divider(
              color: isDark ? Colors.white12 : Colors.black12),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal",
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary)),
              Text(
                "₹${group.shopTotal.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 10),

          // ── Fulfillment toggle ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _fulfillmentTab(
                  label: "Delivery",
                  icon: Icons.delivery_dining_rounded,
                  selected: isDelivery,
                  isDark: isDark,
                  onTap: () => setState(() =>
                      fulfillment.type = FulfillmentType.delivery),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _fulfillmentTab(
                  label: "Pickup",
                  icon: Icons.storefront_rounded,
                  selected: !isDelivery,
                  isDark: isDark,
                  onTap: () => setState(() =>
                      fulfillment.type = FulfillmentType.pickup),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Delivery details ───────────────────────────────────
          if (isDelivery) ...[
            // Address field
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: TextField(
                controller: addressCtrl,
                maxLines: 2,
                style: GoogleFonts.inter(
                    color: textPrimary, fontSize: 14),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Enter delivery address...",
                  hintStyle: GoogleFonts.inter(
                      color: textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: textSecondary, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Estimated delivery time badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    "Estimated delivery: 30–60 min",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ]

          // ── Pickup details ─────────────────────────────────────
          else ...[
            Text("Select pickup slot",
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
            const SizedBox(height: 8),
            ..._pickupSlots.map((slot) {
              final bool selected = fulfillment.pickupSlot == slot;
              return GestureDetector(
                onTap: () =>
                    setState(() => fulfillment.pickupSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF16A34A)
                            .withValues(alpha: 0.1)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF16A34A)
                              .withValues(alpha: 0.5)
                          : (isDark
                              ? Colors.white12
                              : Colors.black12),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? const Color(0xFF16A34A)
                            : textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(slot,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected
                                ? const Color(0xFF16A34A)
                                : textPrimary,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _fulfillmentTab({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF16A34A)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF16A34A)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : (isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}