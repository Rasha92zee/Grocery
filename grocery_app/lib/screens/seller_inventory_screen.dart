import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class SellerInventoryScreen extends StatefulWidget {
  const SellerInventoryScreen({super.key});

  @override
  State<SellerInventoryScreen> createState() => _SellerInventoryScreenState();
}

class _SellerInventoryScreenState extends State<SellerInventoryScreen> {
  List<ShopInventoryItem> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    final items = await ApiService.fetchSellerInventory();
    dev.log("sellerInventory: ${items.length}", name: 'SellerInventoryScreen');
    if (mounted) setState(() { _inventory = items; _isLoading = false; });
  }

  void _showAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddProductSheet(onAdded: () {
        Navigator.pop(ctx);
        _fetchInventory();
      }),
    );
  }

  void _showEditSheet(ShopInventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditInventorySheet(
        item: item,
        onSaved: () {
          Navigator.pop(ctx);
          _fetchInventory();
        },
        onDeleted: () {
          Navigator.pop(ctx);
          _fetchInventory();
        },
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

    return Stack(
      children: [
        _inventory.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inventory_2_outlined, size: 72,
                      color: isDark ? Colors.white12 : Colors.black12),
                  const SizedBox(height: 20),
                  Text("No products yet",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white54 : Colors.black45)),
                  const SizedBox(height: 8),
                  Text("Tap + to add products from the catalog",
                      style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
                ]),
              )
            : RefreshIndicator(
                color: const Color(0xFF16A34A),
                onRefresh: _fetchInventory,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: _inventory.length,
                  itemBuilder: (context, i) {
                    final item = _inventory[i];
                    String imageUrl = item.imageUrl;
                    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                      imageUrl = "http://127.0.0.1:8000$imageUrl";
                    }

                    return GestureDetector(
                      onTap: () => _showEditSheet(item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: Row(
                          children: [
                            // Image
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(borderRadius: BorderRadius.circular(12),
                                      child: Image.network(imageUrl, fit: BoxFit.contain,
                                          errorBuilder: (ctx, err, stack) => const Icon(
                                              Icons.shopping_bag_outlined, color: Color(0xFF16A34A))))
                                  : const Icon(Icons.shopping_bag_outlined, color: Color(0xFF16A34A)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.productName,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600,
                                        fontSize: 14, color: textPrimary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text("${item.stockQuantity} in stock",
                                    style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                              ]),
                            ),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text("₹${item.price.toStringAsFixed(0)}",
                                  style: const TextStyle(color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isAvailable
                                      ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                      : Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.isAvailable ? "Active" : "Hidden",
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold,
                                      color: item.isAvailable ? const Color(0xFF16A34A) : Colors.redAccent),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

        // FAB
        Positioned(
          bottom: 24, right: 24,
          child: GestureDetector(
            onTap: _showAddProductSheet,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                    blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ADD PRODUCT SHEET ────────────────────────────────────────────────────────

class _AddProductSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddProductSheet({required this.onAdded});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  List<MasterProduct> _catalog = [];
  List<MasterProduct> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  MasterProduct? _selected;
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() => _filtered = _catalog
          .where((p) => p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q))
          .toList());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final products = await ApiService.fetchMasterProducts();
    if (mounted) setState(() { _catalog = products; _filtered = products; _isLoading = false; });
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final price = double.tryParse(_priceCtrl.text);
    final stock = int.tryParse(_stockCtrl.text);
    if (price == null || stock == null) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService.addToSellerInventory(_selected!.id, price, stock);
    dev.log("addToInventory: $success", name: 'SellerInventory');

    if (success) {
      widget.onAdded();
    } else {
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(const SnackBar(content: Text("Failed to add product")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(_selected == null ? "Add from Catalog" : "Set Price & Stock",
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
            ),
            const SizedBox(height: 12),

            if (_selected == null) ...[
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.inter(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search catalog...",
                      hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final p = _filtered[i];
                          String imageUrl = p.photo;
                          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                            imageUrl = "http://127.0.0.1:8000$imageUrl";
                          }
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selected = p;
                                _priceCtrl.text = p.referencePrice.toStringAsFixed(0);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: imageUrl.isNotEmpty
                                      ? ClipRRect(borderRadius: BorderRadius.circular(10),
                                          child: Image.network(imageUrl, fit: BoxFit.contain,
                                              errorBuilder: (ctx, err, stack) => const Icon(
                                                  Icons.shopping_bag_outlined, color: Color(0xFF16A34A), size: 20)))
                                      : const Icon(Icons.shopping_bag_outlined, color: Color(0xFF16A34A), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600,
                                      fontSize: 14, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(p.brand, style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                                ])),
                                Text("₹${p.referencePrice.toStringAsFixed(0)}",
                                    style: const TextStyle(color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold, fontSize: 14)),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ] else ...[
              // Price & stock form
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    // Selected product preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_selected!.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600,
                                fontSize: 14, color: textPrimary))),
                        GestureDetector(
                          onTap: () => setState(() => _selected = null),
                          child: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    _inputField("Your Price (₹)", _priceCtrl, TextInputType.number, textPrimary, textSecondary, isDark,
                        hint: "e.g. 45"),
                    const SizedBox(height: 14),
                    _inputField("Stock Quantity", _stockCtrl, TextInputType.number, textPrimary, textSecondary, isDark,
                        hint: "e.g. 50"),
                    const SizedBox(height: 28),

                    GestureDetector(
                      onTap: _isSaving ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? const Color(0xFF16A34A).withValues(alpha: 0.6)
                              : const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                              blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: _isSaving
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("Add to My Shop",
                                style: GoogleFonts.inter(color: Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 15))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl,
      TextInputType keyboard, Color textPrimary, Color textSecondary, bool isDark,
      {String hint = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: GoogleFonts.inter(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    ]);
  }
}

// ─── EDIT INVENTORY SHEET ─────────────────────────────────────────────────────

class _EditInventorySheet extends StatefulWidget {
  final ShopInventoryItem item;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;
  const _EditInventorySheet({required this.item, required this.onSaved, required this.onDeleted});

  @override
  State<_EditInventorySheet> createState() => _EditInventorySheetState();
}

class _EditInventorySheetState extends State<_EditInventorySheet> {
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late bool _isAvailable;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.item.price.toStringAsFixed(0));
    _stockCtrl = TextEditingController(text: widget.item.stockQuantity.toString());
    _isAvailable = widget.item.isAvailable;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_priceCtrl.text);
    final stock = int.tryParse(_stockCtrl.text);
    if (price == null || stock == null) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService.updateInventoryItem(
        widget.item.id, price, stock, _isAvailable);
    if (success) {
      widget.onSaved();
    } else {
      if (mounted) setState(() => _isSaving = false);
      messenger.showSnackBar(const SnackBar(content: Text("Failed to save")));
    }
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService.removeInventoryItem(widget.item.id);
    if (success) {
      widget.onDeleted();
    } else {
      messenger.showSnackBar(const SnackBar(content: Text("Failed to remove")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24,
          MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(widget.item.productName,
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 20),

          // Price
          Text("Price (₹)", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 6),
          _field(_priceCtrl, TextInputType.number, textPrimary, textSecondary, isDark),
          const SizedBox(height: 14),

          // Stock
          Text("Stock", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 6),
          _field(_stockCtrl, TextInputType.number, textPrimary, textSecondary, isDark),
          const SizedBox(height: 16),

          // Available toggle
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Visible to customers",
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            Switch(
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
              activeThumbColor: const Color(0xFF16A34A),        // thumb color
              activeTrackColor: const Color(0xFF16A34A).withValues(alpha: 0.5),
            ),
          ]),
          const SizedBox(height: 24),

          Row(children: [
            // Delete
            GestureDetector(
              onTap: _delete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Center(child: _isSaving
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Save Changes",
                          style: GoogleFonts.inter(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 14))),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, TextInputType keyboard,
      Color textPrimary, Color textSecondary, bool isDark) =>
      Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: GoogleFonts.inter(color: textPrimary, fontSize: 15),
          decoration: const InputDecoration(border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
      );
}