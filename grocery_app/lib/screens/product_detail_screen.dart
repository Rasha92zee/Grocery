import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final MasterProduct product;
  final String heroTag;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.heroTag = '',
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<ShopListing> _shops = [];
  List<ShopListing> _sortedShops = [];
  bool _isLoading = true;
  bool _sortByPrice = true;

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    final shops = await ApiService.fetchShopsForProduct(widget.product.id);
    dev.log("fetchShops: got ${shops.length} shops", name: 'ProductDetailScreen');
    if (mounted) {
      setState(() {
        _shops = shops;
        _sortedShops = _applySorting(shops);
        _isLoading = false;
      });
    }
  }

  List<ShopListing> _applySorting(List<ShopListing> shops) {
    final sorted = List<ShopListing>.from(shops);
    if (_sortByPrice) {
      sorted.sort((a, b) => a.price.compareTo(b.price));
    } else {
      sorted.sort((a, b) => a.shopName.compareTo(b.shopName));
    }
    return sorted;
  }

  void _toggleSort() {
    setState(() {
      _sortByPrice = !_sortByPrice;
      _sortedShops = _applySorting(_shops);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final favProvider = Provider.of<FavoritesProvider>(context);
    final bool isFav = favProvider.isFavorite(widget.product.id);

    final Color bg =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color cardBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    String imageUrl = widget.product.photo;
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = "http://127.0.0.1:8000$imageUrl";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // ── Hero App Bar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                GestureDetector(
                  onTap: () => favProvider.toggleFavorite(widget.product),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isFav
                          ? Colors.red.withValues(alpha: 0.1)
                          : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: bg,
                  padding: const EdgeInsets.fromLTRB(40, 80, 40, 20),
                  child: Hero(
                    tag: widget.heroTag.isNotEmpty
                        ? widget.heroTag
                        : 'product-${widget.product.id}',
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.4),
                            ),
                          )
                        : Icon(
                            Icons.shopping_basket_outlined,
                            size: 80,
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.4),
                          ),
                  ),
                ),
              ),
            ),

            // ── Product Info ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(widget.product.brand,
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "₹${widget.product.referencePrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                "market rate",
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF16A34A)
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(widget.product.displayWeight,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: textSecondary)),
                    ),

                    if (widget.product.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text("About",
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      const SizedBox(height: 6),
                      Text(widget.product.description,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.5)),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Sort Toggle ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Available at",
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary)),
                    GestureDetector(
                      onTap: _toggleSort,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _sortByPrice
                                  ? Icons.attach_money_rounded
                                  : Icons.sort_by_alpha_rounded,
                              size: 14,
                              color: const Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _sortByPrice ? "Cheapest first" : "A–Z",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Shop Listings ────────────────────────────────────────────
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: Color(0xFF16A34A)),
                      ),
                    ),
                  )
                : _sortedShops.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              "No shops currently carry this product",
                              style: GoogleFonts.inter(
                                  color: textSecondary, fontSize: 14),
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildShopCard(
                              _sortedShops[index],
                              index,
                              isDark,
                              cardBg,
                              textPrimary,
                              textSecondary,
                            ),
                            childCount: _sortedShops.length,
                          ),
                        ),
                      ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(
    ShopListing shop,
    int index,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    final bool isCheapest =
        _sortByPrice && index == 0 && _sortedShops.length > 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCheapest
            ? const Color(0xFF16A34A).withValues(alpha: 0.08)
            : cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCheapest
              ? const Color(0xFF16A34A).withValues(alpha: 0.4)
              : (isDark ? Colors.white12 : Colors.black12),
          width: isCheapest ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCheapest
                  ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: isCheapest
                  ? const Color(0xFF16A34A)
                  : (isDark ? Colors.white38 : Colors.black38),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shop.shopName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCheapest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "BEST PRICE",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text("${shop.stockQuantity} in stock",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: textSecondary)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${shop.price.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCheapest ? const Color(0xFF16A34A) : textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  // ✅ Capture BEFORE await — _buildShopCard's context is a
                  // closure context, not State.context, so mounted won't help.
                  // Storing messenger before the gap is the correct fix.
                  final messenger = ScaffoldMessenger.of(context);
                  final cart =
                      Provider.of<CartProvider>(context, listen: false);

                  final success = await cart.addToCart(shop.inventoryId);

                  dev.log(
                    "addToCart inventoryId=${shop.inventoryId} success=$success",
                    name: 'ProductDetailScreen',
                  );

                  // ✅ Safe — uses pre-captured messenger, no context after await
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? "Added from ${shop.shopName}"
                          : "Failed to add"),
                      backgroundColor: success
                          ? const Color(0xFF16A34A)
                          : Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Add",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}