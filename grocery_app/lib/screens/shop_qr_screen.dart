import 'dart:developer' as dev;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme_provider.dart';
import '../models/shop_model.dart';

class ShopQrScreen extends StatefulWidget {
  final ShopModel shop;
  const ShopQrScreen({super.key, required this.shop});

  @override
  State<ShopQrScreen> createState() => _ShopQrScreenState();
}

class _ShopQrScreenState extends State<ShopQrScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  /// The QR data — encodes the shop slug as a deep link
  String get _qrData => 'berrybasket://shop/${widget.shop.shopSlug}';

  Future<Uint8List?> _captureQr() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      dev.log("captureQr error: $e", name: 'ShopQrScreen');
      return null;
    }
  }

  Future<void> _shareQr() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _captureQr();
      if (bytes == null) throw Exception("Failed to capture QR");
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.shop.shopSlug}_qr.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Find ${widget.shop.shopName} on Berry Basket!',
      );
    } catch (e) {
      dev.log("shareQr error: $e", name: 'ShopQrScreen');
      messenger.showSnackBar(
        const SnackBar(content: Text("Failed to share QR code")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveQr() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _captureQr();
      if (bytes == null) throw Exception("Failed to capture QR");
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/${widget.shop.shopSlug}_qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      messenger.showSnackBar(
        SnackBar(
          content: Text("QR saved to ${file.path}"),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      dev.log("saveQr error: $e", name: 'ShopQrScreen');
      messenger.showSnackBar(
        const SnackBar(content: Text("Failed to save QR code")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          "Shop QR Code",
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, color: textPrimary, fontSize: 18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shop name header
              Text(
                widget.shop.shopName,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              if (widget.shop.address.isNotEmpty)
                Text(
                  widget.shop.address,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: textSecondary),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 40),

              // QR code card — wrapped in RepaintBoundary for capture
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF16A34A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shopping_basket_rounded,
                                color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Berry Basket",
                            style: GoogleFonts.cookie(
                              fontSize: 20,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.shop.shopSlug,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Scan to find this shop on Berry Basket",
                style: GoogleFonts.inter(
                    fontSize: 13, color: textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Action buttons
              Row(
                children: [
                  // Share button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaving ? null : _shareQr,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16A34A)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.share_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text("Share",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Download button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaving ? null : _saveQr,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF16A34A)),
                                  )
                                : Icon(Icons.download_rounded,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Save",
                              style: GoogleFonts.inter(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}