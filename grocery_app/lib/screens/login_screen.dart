import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import '../theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ Django & UI State Flags (Defined here to avoid "not defined" errors)
  bool _isLoading = false;
  bool _isShopOwner = false; 

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  // ✅ Validation & Navigation Logic
  Future<void> _handleContinue() async {
    String phone = _phoneController.text.trim();
    String name = _nameController.text.trim();

    // 1. Name Validation
    if (name.isEmpty) {
      _showError("Please enter your full name");
      return;
    }

    // 2. Strict 10-digit Regex Validation
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(phone)) {
      _showError("Please enter a valid 10-digit phone number");
      return;
    }

    setState(() => _isLoading = true);

    // 3. API Call to Django
    bool success = await _authService.sendOtp(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            phoneNumber: phone,
            fullName: name,
            isShopOwner: _isShopOwner, 
          ),
        ),
      );
    } else {
      _showError("Failed to send OTP. Check your connection.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ Unified Input Field Helper
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF16A34A), size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const RadialGradient(colors: [Color(0xFF1A2E28), Color(0xFF0F0F0F)])
                  : const RadialGradient(colors: [Color(0xFFF9FFF9), Color(0xFFFFFFFF)]),
            ),
          ),

          // Theme Toggle
          Positioned(
            top: 60,
            right: 25,
            child: GestureDetector(
              onTap: () => themeProvider.toggleTheme(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: isDark ? Colors.amber : Colors.indigo,
                  size: 20,
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Icon(Icons.shopping_basket_outlined, size: 70, color: const Color(0xFF16A34A)),
                  
                  // Brand & Tagline
                  Text(
                    "Berry Basket",
                    style: GoogleFonts.cookie(fontSize: 52, color: const Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Fresh Groceries, delivered fast",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Inputs
                  _inputField(
                    controller: _nameController,
                    hint: "Full Name",
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 15),
                  _inputField(
                    controller: _phoneController,
                    hint: "Phone Number",
                    icon: Icons.phone_android_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),

                  // Shop Owner Toggle
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: _isShopOwner,
                          activeColor: const Color(0xFF16A34A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (value) => setState(() => _isShopOwner = value!),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isShopOwner = !_isShopOwner),
                        child: Text(
                          "Register as Shop Owner",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Continue Button
                  Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF15803D)]),
                      boxShadow: isDark ? [BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))] : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Continue", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  // ✅ UPDATED FOOTER WITH DOT SEPARATOR
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "SECURE LOGIN",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white24 : Colors.black26,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        "2M+ USERS",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white24 : Colors.black26,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}