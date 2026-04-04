import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

class AuthService {
  // Replace with your Mac's IP or your deployed Django URL
  final String baseUrl = "http://127.0.0.1:8000";

  Future<bool> sendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/send-otp/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": phoneNumber}),
      );

      if (response.statusCode == 200) {
        dev.log("OTP Sent Successfully");
        return true;
      } else {
        dev.log("Failed to send OTP: ${response.body}");
        return false;
      }
    } catch (e) {
      dev.log("Error connecting to Django: $e");
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/auth/verify-otp/',
        ), // Match your Django URL from screenshot
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": phoneNumber, "otp": otp}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
