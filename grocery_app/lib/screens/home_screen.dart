import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/favorites_provider.dart';
import 'product_detail_screen.dart';
import '../providers/location_provider.dart';

class MasterProductGrid extends StatefulWidget {
  const MasterProductGrid({super.key});

  @override
  State<MasterProductGrid> createState() => _MasterProductGridState();
}

class _MasterProductGridState extends State<MasterProductGrid> {
  List<MasterProduct> _allProducts = [];
  List<MasterProduct> _filteredProducts = [];
  bool isLoading = true;
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    "All",
    "Fruits And Vegetables",
    "Eggs, Meat & Fish",
    "Bakery, Cakes & Dairy",
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
      _applyFilters();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final List<MasterProduct> data = await ApiService.fetchMasterProducts();
      print("Fetched ${data.length} products from Django.");
      if (mounted) {
        setState(() {
          _allProducts = data;
          _filteredProducts = data;
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching products: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterProducts(int index) {
    setState(() => _selectedCategoryIndex = index);
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesCategory = _selectedCategoryIndex == 0 ||
            p.category == _categories[_selectedCategoryIndex];
        final matchesSearch = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.brand.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
            )
          : _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    return CustomScrollView(
      key: const ValueKey('body'),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildSearchBar(isDark)),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildCategoryList(isDark)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _searchQuery.isNotEmpty
                  ? "${_filteredProducts.length} result${_filteredProducts.length == 1 ? '' : 's'} for \"$_searchQuery\""
                  : "Fresh Picks",
              style: GoogleFonts.inter(
                fontSize: _searchQuery.isNotEmpty ? 16 : 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _buildProductGrid(isDark),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search fruits, vegetables, brands...",
            hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: textSecondary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(bool isDark) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => _filterProducts(index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                        : [],
                    border: Border.all(
                      color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  child: Text(
                    _categories[index],
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.only(top: 5, right: 12),
                    height: 4,
                    width: 4,
                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(bool isDark) {
    if (_filteredProducts.isEmpty) {
      return SizedBox(
        key: ValueKey(_selectedCategoryIndex),
        height: 200,
        child: Center(
          child: Text(
            "No products in this category",
            style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ),
      );
    }

    return GridView.builder(
      key: ValueKey(_selectedCategoryIndex),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index], isDark),
    );
  }

  Widget _buildProductCard(MasterProduct product, bool isDark) {
    String imageUrl = product.photo;
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = "http://127.0.0.1:8000$imageUrl";
    }

    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        final favProvider = Provider.of<FavoritesProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
        final bool isFav = favProvider.isFavorite(product.id);

        return GestureDetector(
          // ✅ Tap anywhere on card → go to ProductDetailScreen
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                heroTag: 'product-${product.id}',
              ),
            ),
          ),
          child: MouseRegion(
            onEnter: (_) => setStateCard(() => isHovered = true),
            onExit: (_) => setStateCard(() => isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                boxShadow: isHovered
                    ? [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2)]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: Hero(
                              tag: 'product-${product.id}',
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)));
                                      },
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.shopping_bag_outlined, size: 60, color: Color(0xFF16A34A)),
                                    )
                                  : const Icon(Icons.shopping_basket_outlined, size: 60, color: Color(0xFF16A34A)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.displayWeight,
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
                        ),
                        // ✅ Nearest shop distance badge
                        if (locationProvider.hasLocation && product.nearestShopDistance != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: [
                              Icon(Icons.near_me_rounded, size: 11,
                                  color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 3),
                              Text(
                                locationProvider.formatDistance(
                                    product.nearestShopLat, product.nearestShopLng),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white38 : Colors.black38),
                              ),
                            ]),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ✅ Show reference_price on the card
                            Text(
                              "₹${product.referencePrice.toStringAsFixed(0)}",
                              style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            // ✅ + button navigates to product detail (same as card tap)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    product: product,
                                    heroTag: 'product-${product.id}',
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Heart icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => favProvider.toggleFavorite(product),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isFav ? Colors.red.withValues(alpha: 0.1) : (isDark ? Colors.black26 : Colors.white),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                        ),
                        child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}