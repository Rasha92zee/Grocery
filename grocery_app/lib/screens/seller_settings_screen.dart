import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';

class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  State<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadShopDetails();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShopDetails() async {
    final shop = await ApiService.fetchMyShop();
    if (mounted && shop != null) {
      setState(() {
        _nameCtrl.text = shop['shop_name'] ?? '';
        _addressCtrl.text = shop['address'] ?? '';
        _descCtrl.text = shop['description'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final success = await ApiService.updateMyShop(
      shopName: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
    dev.log("updateMyShop: $success", name: 'SellerSettings');

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shop_name', _nameCtrl.text.trim());
      messenger.showSnackBar(SnackBar(
        content: const Text("Shop details saved!"),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text("Failed to save. Please try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Shop logo placeholder
        Center(
          child: Stack(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 40),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text("Shop Logo", style: GoogleFonts.inter(fontSize: 12, color: textSecondary))),
        const SizedBox(height: 28),

        _field("Shop Name", _nameCtrl, textPrimary, textSecondary, isDark,
            icon: Icons.storefront_rounded),
        const SizedBox(height: 16),
        _field("Address", _addressCtrl, textPrimary, textSecondary, isDark,
            icon: Icons.location_on_outlined, maxLines: 2),
        const SizedBox(height: 16),
        _field("Description", _descCtrl, textPrimary, textSecondary, isDark,
            icon: Icons.description_outlined, maxLines: 4,
            hint: "Tell customers about your shop..."),
        const SizedBox(height: 32),

        GestureDetector(
          onTap: _isSaving ? null : _save,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isSaving
                  ? const Color(0xFF16A34A).withValues(alpha: 0.6)
                  : const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(child: _isSaving
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Save Changes",
                    style: GoogleFonts.inter(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 16))),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      Color textPrimary, Color textSecondary, bool isDark,
      {IconData? icon, int maxLines = 1, String hint = ''}) {
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
          maxLines: maxLines,
          style: GoogleFonts.inter(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: textSecondary),
            prefixIcon: icon != null ? Icon(icon, color: textSecondary, size: 20) : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    ]);
  }
}