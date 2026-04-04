import 'dart:developer' as dev;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item_model.dart';
import '../models/shop_model.dart';
import '../screens/order_confirmation_screen.dart'; 

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ─── AUTH HEADERS ───────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── MASTER PRODUCTS ────────────────────────────────────────────────────────

  static Future<List<MasterProduct>> fetchMasterProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => MasterProduct.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      dev.log("fetchMasterProducts error: $e", name: 'ApiService');
      return [];
    }
  }

  // ─── SHOP LISTINGS ──────────────────────────────────────────────────────────

  static Future<List<ShopListing>> fetchShopsForProduct(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/shops/'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => ShopListing.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      dev.log("fetchShopsForProduct error: $e", name: 'ApiService');
      return [];
    }
  }

  // ─── SHOPS ──────────────────────────────────────────────────────────────────

  static Future<List<ShopModel>> fetchShops() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/shops/'));
      dev.log("fetchShops: ${response.statusCode}", name: 'ApiService');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => ShopModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      dev.log("fetchShops error: $e", name: 'ApiService');
      return [];
    }
  }

  // ─── CART ───────────────────────────────────────────────────────────────────

  static Future<List<CartItemModel>> fetchCart() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/cart/'),
        headers: headers,
      );
      dev.log("fetchCart: ${response.statusCode}");
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => CartItemModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      dev.log("fetchCart error: $e", name: 'ApiService');
      return [];
    }
  }

  // ✅ POST /api/cart/ — matches Django router CartViewSet.create
  static Future<bool> addToCart(int inventoryId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/cart/'),
        headers: headers,
        body: json.encode({'inventory_id': inventoryId}),
      );
      dev.log("addToCart: ${response.statusCode} ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      dev.log("addToCart error: $e", name: 'ApiService');
      return false;
    }
  }

  // ✅ PATCH /api/cart/<id>/ — matches CartItemUpdateView
  static Future<bool> updateCartItem(int cartItemId, int quantity) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/cart/$cartItemId/'),
        headers: headers,
        body: json.encode({'quantity': quantity}),
      );
      dev.log("updateCartItem: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      dev.log("updateCartItem error: $e", name: 'ApiService');
      return false;
    }
  }

  // ✅ DELETE /api/cart/<id>/ — matches Django router CartViewSet.destroy
  static Future<bool> removeCartItem(int cartItemId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$cartItemId/'),
        headers: headers,
      );
      dev.log("removeCartItem: ${response.statusCode}");
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      dev.log("removeCartItem error: $e", name: 'ApiService');
      return false;
    }
  }

  // ─── CHECKOUT ───────────────────────────────────────────────────────────────

  // ✅ POST /api/checkout/ — sends fulfillment choice per shop
  static Future<bool> checkout({
    Map<String, ShopFulfillment>? fulfillments,
  }) async {
    try {
      final headers = await _authHeaders();

      // Build fulfillment map: { shopName: { type, address, pickup_slot } }
      final Map<String, dynamic> fulfillmentData = {};
      if (fulfillments != null) {
        fulfillments.forEach((shopName, f) {
          fulfillmentData[shopName] = {
            'fulfillment_type': f.type == FulfillmentType.delivery ? 'DELIVERY' : 'PICKUP',
            'delivery_address': f.deliveryAddress,
            'pickup_slot': f.pickupSlot,
          };
        });
      }

      final response = await http.post(
        Uri.parse('$baseUrl/checkout/'),
        headers: headers,
        body: json.encode({'fulfillments': fulfillmentData}),
      );
      dev.log("checkout: ${response.statusCode} ${response.body}", name: 'ApiService');
      return response.statusCode == 201;
    } catch (e) {
      dev.log("checkout error: $e", name: 'ApiService');
      return false;
    }
  }

  // ─── ORDERS ─────────────────────────────────────────────────────────────────

  // ✅ GET /api/orders/ — returns customer orders with items and status
  static Future<List<OrderModel>> fetchOrders() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/'),
        headers: headers,
      );
      dev.log("fetchOrders: ${response.statusCode}", name: 'ApiService');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => OrderModel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      dev.log("fetchOrders error: $e", name: 'ApiService');
      return [];
    }
  }

  // ✅ PATCH /api/orders/<id>/update/ — cancel a PENDING order
  static Future<bool> cancelOrder(int orderId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/update/'),
        headers: headers,
        body: json.encode({'status': 'CANCELLED'}),
      );
      dev.log("cancelOrder $orderId: ${response.statusCode}", name: 'ApiService');
      return response.statusCode == 200;
    } catch (e) {
      dev.log("cancelOrder error: $e", name: 'ApiService');
      return false;
    }
  }

  // ─── FAVOURITES ─────────────────────────────────────────────────────────────

  static Future<List<MasterProduct>> fetchFavorites() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => MasterProduct.fromJson(j['product'])).toList();
      }
      return [];
    } catch (e) {
      dev.log("fetchFavorites error: $e", name: 'ApiService');
      return [];
    }
  }

  static Future<bool?> toggleFavorite(int productId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/favorites/toggle/$productId/'),
        headers: headers,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body)['is_favorite'] as bool;
      }
      return null;
    } catch (e) {
      dev.log("toggleFavorite error: $e", name: 'ApiService');
      return null;
    }
  }

  // ─── SELLER ──────────────────────────────────────────────────────────────────

  static Future<List<ShopInventoryItem>> fetchSellerInventory() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/shop-inventory/'),
        headers: headers,
      );
      dev.log("fetchSellerInventory: ${response.statusCode}", name: 'ApiService');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((j) => ShopInventoryItem.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      dev.log("fetchSellerInventory error: $e", name: 'ApiService');
      return [];
    }
  }

  static Future<bool> addToSellerInventory(int productId, double price, int stock) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/shop-inventory/'),
        headers: headers,
        body: json.encode({'product': productId, 'price': price, 'stock_quantity': stock, 'is_available': true}),
      );
      dev.log("addToSellerInventory: ${response.statusCode} ${response.body}", name: 'ApiService');
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      dev.log("addToSellerInventory error: $e", name: 'ApiService');
      return false;
    }
  }

  static Future<bool> updateInventoryItem(int itemId, double price, int stock, bool isAvailable) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/shop-inventory/$itemId/'),
        headers: headers,
        body: json.encode({'price': price, 'stock_quantity': stock, 'is_available': isAvailable}),
      );
      dev.log("updateInventoryItem: ${response.statusCode}", name: 'ApiService');
      return response.statusCode == 200;
    } catch (e) {
      dev.log("updateInventoryItem error: $e", name: 'ApiService');
      return false;
    }
  }

  static Future<bool> removeInventoryItem(int itemId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/shop-inventory/$itemId/'),
        headers: headers,
      );
      dev.log("removeInventoryItem: ${response.statusCode}", name: 'ApiService');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      dev.log("removeInventoryItem error: $e", name: 'ApiService');
      return false;
    }
  }

  static Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/update/'),
        headers: headers,
        body: json.encode({'status': status}),
      );
      dev.log("updateOrderStatus $orderId -> $status: ${response.statusCode}", name: 'ApiService');
      return response.statusCode == 200;
    } catch (e) {
      dev.log("updateOrderStatus error: $e", name: 'ApiService');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchMyShop() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse('$baseUrl/my-shop/'), headers: headers);
      dev.log("fetchMyShop: ${response.statusCode}", name: 'ApiService');
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      dev.log("fetchMyShop error: $e", name: 'ApiService');
      return null;
    }
  }

  static Future<bool> updateMyShop({required String shopName, required String address, required String description}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/my-shop/'),
        headers: headers,
        body: json.encode({'shop_name': shopName, 'address': address, 'description': description}),
      );
      dev.log("updateMyShop: ${response.statusCode}", name: 'ApiService');
      return response.statusCode == 200;
    } catch (e) {
      dev.log("updateMyShop error: $e", name: 'ApiService');
      return false;
    }
  }
}