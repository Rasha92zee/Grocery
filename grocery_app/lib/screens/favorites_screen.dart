import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh favourites every time this tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final favProvider = Provider.of<FavoritesProvider>(context);

    if (favProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      );
    }

    if (favProvider.favoriteProducts.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "${favProvider.favoriteProducts.length} Saved Item${favProvider.favoriteProducts.length == 1 ? '' : 's'}",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFavoriteCard(
                favProvider.favoriteProducts[index],
                isDark,
                favProvider,
              ),
              childCount: favProvider.favoriteProducts.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 72,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 20),
          Text(
            "No saved items yet",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the ❤️ on any product to save it here",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FAVOURITE CARD ───────────────────────────────────────────────────────

  Widget _buildFavoriteCard(
    MasterProduct product,
    bool isDark,
    FavoritesProvider favProvider,
  ) {
    String imageUrl = product.photo;
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = "http://127.0.0.1:8000$imageUrl";
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: product,
            heroTag: 'fav-product-${product.id}',
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            )
          ],
        ),
      child: Stack(
        children: [
          // ── Card content ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'fav-product-${product.id}',
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF16A34A),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.shopping_bag_outlined,
                                size: 60,
                                color: Color(0xFF16A34A),
                              ),
                            )
                          : const Icon(
                              Icons.shopping_basket_outlined,
                              size: 60,
                              color: Color(0xFF16A34A),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  product.displayWeight,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${product.referencePrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Remove from favourites (top-right) ─────────────────────
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => favProvider.toggleFavorite(product),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    ), // AnimatedContainer
    ); // GestureDetector
  }
}