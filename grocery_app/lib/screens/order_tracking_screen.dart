import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme_provider.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderModel _order;
  bool _isRefreshing = false;

  // Status pipeline
  final List<_TrackingStep> _steps = [
    _TrackingStep('PENDING',   'Order Placed',    Icons.receipt_long_rounded,     'Your order has been received'),
    _TrackingStep('PACKING',   'Being Packed',    Icons.inventory_2_rounded,      'Shop is packing your items'),
    _TrackingStep('READY',     'Ready',           Icons.check_circle_rounded,     'Your order is ready'),
    _TrackingStep('COMPLETED', 'Delivered',       Icons.celebration_rounded,      'Order completed!'),
  ];

  // Pickup pipeline
  final List<_TrackingStep> _pickupSteps = [
    _TrackingStep('PENDING',   'Order Placed',    Icons.receipt_long_rounded,     'Your order has been received'),
    _TrackingStep('PACKING',   'Being Packed',    Icons.inventory_2_rounded,      'Shop is packing your items'),
    _TrackingStep('READY',     'Ready for Pickup', Icons.storefront_rounded,      'Head to the shop to collect your order'),
    _TrackingStep('COMPLETED', 'Collected',       Icons.celebration_rounded,      'Order completed!'),
  ];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    final orders = await ApiService.fetchOrders();
    final updated = orders.firstWhere(
      (o) => o.id == _order.id,
      orElse: () => _order,
    );
    dev.log("refreshOrder ${_order.id}: ${updated.status}", name: 'OrderTrackingScreen');
    if (mounted) setState(() { _order = updated; _isRefreshing = false; });
  }

  int get _currentStepIndex {
    final pipeline = _order.fulfillmentType == 'PICKUP' ? _pickupSteps : _steps;
    final idx = pipeline.indexWhere((s) => s.status == _order.status);
    return idx == -1 ? 0 : idx;
  }

  Future<void> _openMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    final appleMapsUrl = Uri.parse('maps://?q=$encoded');

    // Try Google Maps first, fall back to Apple Maps, then browser
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getDirections(String address) async {
    final encoded = Uri.encodeComponent(address);
    // Opens Google Maps navigation to the address
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFBF8F3);
    final Color cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white54 : Colors.black45;

    final bool isPickup = _order.fulfillmentType == 'PICKUP';
    final pipeline = isPickup ? _pickupSteps : _steps;
    final int currentStep = _currentStepIndex;

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
        title: Text("Track Order #${_order.id}",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: textPrimary, fontSize: 18)),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)))
                : const Icon(Icons.refresh_rounded, color: Color(0xFF16A34A)),
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [

            // ── Status header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(pipeline[currentStep].icon,
                        color: const Color(0xFF16A34A), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pipeline[currentStep].label,
                            style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A))),
                        const SizedBox(height: 4),
                        Text(pipeline[currentStep].description,
                            style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Tracking stepper ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                children: List.generate(pipeline.length, (i) {
                  final step = pipeline[i];
                  final bool done = i <= currentStep;
                  final bool isLast = i == pipeline.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line + circle
                      SizedBox(
                        width: 32,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: done
                                    ? const Color(0xFF16A34A)
                                    : (isDark ? Colors.white12 : Colors.black12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                done ? Icons.check_rounded : step.icon,
                                color: done ? Colors.white : textSecondary,
                                size: 14,
                              ),
                            ),
                            if (!isLast)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 2,
                                height: 40,
                                color: i < currentStep
                                    ? const Color(0xFF16A34A)
                                    : (isDark ? Colors.white12 : Colors.black12),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.label,
                                  style: GoogleFonts.inter(
                                    fontWeight: done ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                    color: done ? textPrimary : textSecondary,
                                  )),
                              if (i == currentStep)
                                Text(step.description,
                                    style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // ── Fulfillment details ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPickup ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
                        color: const Color(0xFF16A34A), size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPickup ? "Pickup Details" : "Delivery Details",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold,
                            fontSize: 15, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (isPickup) ...[
                    // Pickup slot
                    _detailRow(Icons.access_time_rounded, "Slot", _order.pickupSlot, textPrimary, textSecondary),
                    const SizedBox(height: 8),
                    _detailRow(Icons.storefront_outlined, "From", _order.shopName, textPrimary, textSecondary),
                    const SizedBox(height: 16),
                    // Navigate to shop button
                    if (_order.shopAddress != null && _order.shopAddress!.isNotEmpty)
                      _mapButton("Get directions to shop",
                          Icons.directions_rounded, () => _getDirections(_order.shopAddress!)),
                  ] else ...[
                    // Delivery address
                    _detailRow(Icons.location_on_outlined, "Address",
                        _order.deliveryAddress.isNotEmpty ? _order.deliveryAddress : "Not specified",
                        textPrimary, textSecondary),
                    const SizedBox(height: 8),
                    _detailRow(Icons.access_time_rounded, "Est. time", "30–60 minutes", textPrimary, textSecondary),
                    const SizedBox(height: 16),
                    // Navigate button
                    if (_order.deliveryAddress.isNotEmpty)
                      _mapButton("Track on Maps", Icons.map_rounded,
                          () => _openMaps(_order.deliveryAddress)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Order summary ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order Summary",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold,
                          fontSize: 15, color: textPrimary)),
                  const SizedBox(height: 12),
                  ..._order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text("${item.quantity}×",
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold,
                                fontSize: 13, color: const Color(0xFF16A34A))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.productName,
                            style: GoogleFonts.inter(fontSize: 13, color: textPrimary))),
                        Text("₹${(item.priceAtOrder * item.quantity).toStringAsFixed(0)}",
                            style: GoogleFonts.inter(fontSize: 13,
                                fontWeight: FontWeight.w600, color: textSecondary)),
                      ],
                    ),
                  )),
                  Divider(color: isDark ? Colors.white12 : Colors.black12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total", style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                      Text("₹${_order.totalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: textSecondary),
        const SizedBox(width: 8),
        Text("$label: ", style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
        Expanded(child: Text(value,
            style: GoogleFonts.inter(fontSize: 13,
                fontWeight: FontWeight.w600, color: textPrimary))),
      ],
    );
  }

  Widget _mapButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.3),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _TrackingStep {
  final String status;
  final String label;
  final IconData icon;
  final String description;
  const _TrackingStep(this.status, this.label, this.icon, this.description);
}