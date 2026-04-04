//import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../providers/location_provider.dart';
import '../models/shop_model.dart';
import '../services/api_service.dart';
import 'shop_qr_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  List<ShopModel> _shops = [];
  List<ShopModel> _filtered = [];
  bool _isLoading = true;
  bool _sortByDistance = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _fetchShopsAndLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchShopsAndLocation() async {
    // Request location and fetch shops in parallel
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      ApiService.fetchShops().then((shops) {
        if (mounted)
          setState(() {
            _shops = shops;
            _isLoading = false;
          });
      }),
      locationProvider.requestLocation(),
    ]);

    // Re-sort once both are ready
    if (mounted) _applySortAndFilter();
  }

  void _onSearch() => _applySortAndFilter();

  void _applySortAndFilter() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final query = _searchController.text.toLowerCase();

    List<ShopModel> result = _shops
        .where(
          (s) =>
              s.shopName.toLowerCase().contains(query) ||
              s.address.toLowerCase().contains(query),
        )
        .toList();

    if (_sortByDistance && locationProvider.hasLocation) {
      result.sort((a, b) {
        final da =
            locationProvider.distanceTo(a.latitude, a.longitude) ??
            double.infinity;
        final db =
            locationProvider.distanceTo(b.latitude, b.longitude) ??
            double.infinity;
        return da.compareTo(db);
      });
    } else {
      result.sort((a, b) => a.shopName.compareTo(b.shopName));
    }

    if (mounted) setState(() => _filtered = result);
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _fetchShopsAndLocation();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    @override
    void initState() {
      super.initState();
      _searchController.addListener(_onSearch);
      _fetchShopsAndLocation();

      // ✅ Listen for location updates and re-sort automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<LocationProvider>(
          context,
          listen: false,
        ).addListener(_applySortAndFilter);
      });
    }

    @override
    void dispose() {
      _searchController.dispose();
      // ✅ Remove listener on dispose to avoid memory leak
      Provider.of<LocationProvider>(
        context,
        listen: false,
      ).removeListener(_applySortAndFilter);
      super.dispose();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      );
    }

    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Search shops or areas...",
                hintStyle: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _applySortAndFilter();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // ── Location status + sort toggle ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Location status chip
              Expanded(
                child: Row(
                  children: [
                    if (locationProvider.isLoading)
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Getting location...",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      )
                    else if (locationProvider.hasLocation)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${_filtered.length} shop${_filtered.length == 1 ? '' : 's'} nearby",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          await locationProvider.requestLocation();
                          _applySortAndFilter();
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_off_rounded,
                              size: 14,
                              color: Colors.orange.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Tap to enable location",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.orange.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Sort toggle
              GestureDetector(
                onTap: () {
                  setState(() => _sortByDistance = !_sortByDistance);
                  _applySortAndFilter();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _sortByDistance
                        ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                        : (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _sortByDistance
                          ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _sortByDistance
                            ? Icons.near_me_rounded
                            : Icons.sort_by_alpha_rounded,
                        size: 13,
                        color: _sortByDistance
                            ? const Color(0xFF16A34A)
                            : textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _sortByDistance ? "Nearest" : "A–Z",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _sortByDistance
                              ? const Color(0xFF16A34A)
                              : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Shop list ────────────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmptyState(isDark, textSecondary)
              : RefreshIndicator(
                  color: const Color(0xFF16A34A),
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) => _buildShopCard(
                      _filtered[index],
                      isDark,
                      textPrimary,
                      textSecondary,
                      locationProvider,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildShopCard(
    ShopModel shop,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    LocationProvider locationProvider,
  ) {
    final Color cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final String distanceLabel = locationProvider.formatDistance(
      shop.latitude,
      shop.longitude,
    );
    final double? distanceKm = locationProvider.distanceTo(
      shop.latitude,
      shop.longitude,
    );
    // Highlight shops within 1km
    final bool isNearby = distanceKm != null && distanceKm < 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNearby
              ? const Color(0xFF16A34A).withValues(alpha: 0.4)
              : (isDark ? Colors.white12 : Colors.black12),
          width: isNearby ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isNearby
                    ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                    : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: isNearby
                    ? const Color(0xFF16A34A)
                    : (isDark ? Colors.white38 : Colors.black38),
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.shopName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (isNearby)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "NEARBY",
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (shop.address.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            shop.address,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Product count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${shop.productCount} products",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      // Distance badge
                      if (distanceLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isNearby
                                ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_walk_rounded,
                                size: 11,
                                color: isNearby
                                    ? const Color(0xFF16A34A)
                                    : textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                distanceLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isNearby
                                      ? const Color(0xFF16A34A)
                                      : textSecondary,
                                  fontWeight: isNearby
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // QR button
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShopQrScreen(shop: shop)),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.qr_code_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 72,
            color: isDark ? Colors.white12 : Colors.black12,
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isNotEmpty
                ? "No shops match your search"
                : "No shops available",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
