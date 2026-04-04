import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final cart = Provider.of<CartProvider>(context);

    final Color bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    if (cart.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)));
    }

    if (cart.isEmpty) {
      return _buildEmptyState(isDark, textSecondary);
    }

    return Column(
      children: [
        // ── Item list ──────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            children: [
              // Shop groups
              ...cart.groupedByShop.map((group) =>
                  _buildShopGroup(group, isDark, cardBg, textPrimary, textSecondary, cart)),

              const SizedBox(height: 16),

              // Grand total card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Grand Total",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          "${cart.totalItemCount} item${cart.totalItemCount == 1 ? '' : 's'} · ${cart.groupedByShop.length} shop${cart.groupedByShop.length == 1 ? '' : 's'}",
                          style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      "₹${cart.grandTotal.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),

        // ── Checkout button ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
          ),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderConfirmationScreen(
                  groups: cart.groupedByShop,
                  grandTotal: cart.grandTotal,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "Review Order  ₹${cart.grandTotal.toStringAsFixed(0)}",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SHOP GROUP ─────────────────────────────────────────────────────────────

  Widget _buildShopGroup(
    CartGroup group,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    CartProvider cart,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Color(0xFF16A34A), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      group.shopName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
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
          ),

          Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),

          // Items
          ...group.items.map((item) =>
              _buildCartItem(item, isDark, textPrimary, textSecondary, cart)),
        ],
      ),
    );
  }

  // ─── CART ITEM ROW ──────────────────────────────────────────────────────────

  Widget _buildCartItem(
    CartItemModel item,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    CartProvider cart,
  ) {
    String imageUrl = item.productImage;
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = "http://127.0.0.1:8000$imageUrl";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Product image
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.shopping_bag_outlined,
                              color: Color(0xFF16A34A),
                            )),
                  )
                : const Icon(Icons.shopping_bag_outlined, color: Color(0xFF16A34A)),
          ),

          const SizedBox(width: 12),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "₹${item.price.toStringAsFixed(0)} each",
                  style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Quantity controls
          Row(
            children: [
              _qtyButton(
                icon: item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                color: item.quantity == 1 ? Colors.redAccent : const Color(0xFF16A34A),
                onTap: () => cart.updateQuantity(item.id, item.quantity - 1),
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    "${item.quantity}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
              _qtyButton(
                icon: Icons.add_rounded,
                color: const Color(0xFF16A34A),
                onTap: () => cart.updateQuantity(item.id, item.quantity + 1),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // Line total
          Text(
            "₹${item.lineTotal.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 72,
              color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add products from any shop to get started",
            style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }
}