import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grocery_app/screens/main_navigation.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'seller_main.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String fullName;
  final bool isShopOwner;
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    required this.isShopOwner,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isVerifying = false;

  @override
  void dispose() {
    for (var node in _focusNodes) {node.dispose();}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const RadialGradient(
                      colors: [Color(0xFF1A2E28), Color(0xFF0F0F0F)])
                  : const RadialGradient(
                      colors: [Color(0xFFF9FFF9), Color(0xFFFFFFFF)]),
            ),
          ),

          // 2. TOP NAV
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      child: Icon(
                        isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        color: isDark ? Colors.amber : Colors.indigo,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. CONTENT
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Verify Code",
                    style: GoogleFonts.cookie(
                        fontSize: 48, color: const Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Sent to ${widget.phoneNumber}",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) => _otpBox(index, isDark)),
                  ),
                  const SizedBox(height: 30),
                  _verifyButton(isDark),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Change Phone Number?",
                      style: TextStyle(
                          color: Colors.green.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int index, bool isDark) {
    return Container(
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: const InputDecoration(counterText: "", border: InputBorder.none),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _verifyButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF15803D)]),
        boxShadow: isDark
            ? [BoxShadow(
                color: Colors.green.withValues(alpha: 0.2), blurRadius: 15)]
            : [],
      ),
      child: ElevatedButton(
        // ✅ No longer passes context as parameter
        onPressed: _isVerifying ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent),
        child: _isVerifying
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Verify & Login",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ✅ No BuildContext parameter — uses State's mounted and captured references
  Future<void> _handleVerify() async {
    final String otp = _controllers.map((c) => c.text).join();

    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the full 4-digit code")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // ✅ Capture context-dependent objects BEFORE any await gap
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/auth/verify-otp/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": widget.phoneNumber,
          "otp": otp,
          "full_name": widget.fullName,
          "is_shop_owner": widget.isShopOwner,
        }),
      );

      dev.log("verifyOtp: ${response.statusCode} ${response.body}",
          name: 'OtpScreen');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        if (!mounted) return;

        await prefs.setString('access_token', data['access']);
        await prefs.setString('user_role', data['role']);
        await prefs.setString('full_name', data['full_name']);

        if (!mounted) return;

        // ✅ Use pre-captured navigator — safe after await
        if (data['role'] == 'shop_owner') {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (ctx) => const SellerMainScreen()),
            (route) => false,
          );
        } else {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (ctx) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        // ✅ Use pre-captured messenger — safe after await
        messenger.showSnackBar(
          SnackBar(content: Text(errorData['error'] ?? "Invalid OTP")),
        );
      }
    } catch (e) {
      dev.log("verifyOtp error: $e", name: 'OtpScreen');
      if (!mounted) return;
      // ✅ Use pre-captured messenger
      messenger.showSnackBar(
        SnackBar(content: Text("Connection Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }
}

class SellerDashboardPlaceholder extends StatelessWidget {
  const SellerDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Dashboard")),
      body: const Center(
        child: Text("Welcome, Shop Owner! Manage your inventory here."),
      ),
    );
  }
}