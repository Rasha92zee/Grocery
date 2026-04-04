import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItemModel> _items = [];
  bool _isLoading = false;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;
  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get grandTotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  List<CartGroup> get groupedByShop {
    final Map<String, List<CartItemModel>> map = {};
    for (final item in _items) {
      map.putIfAbsent(item.shopName, () => []).add(item);
    }
    return map.entries
        .map((e) => CartGroup(shopName: e.key, items: e.value))
        .toList();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    _items = await ApiService.fetchCart();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart(int inventoryId) async {
    final success = await ApiService.addToCart(inventoryId);
    if (success) await loadCart();
    return success;
  }

  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    final item = _items.firstWhere((i) => i.id == cartItemId);
    final oldQty = item.quantity;
    item.quantity = newQuantity;
    notifyListeners();

    final success = await ApiService.updateCartItem(cartItemId, newQuantity);
    if (!success) {
      item.quantity = oldQty;
      notifyListeners();
    }
  }

  Future<void> removeItem(int cartItemId) async {
    final removed = _items.firstWhere((i) => i.id == cartItemId);
    _items.remove(removed);
    notifyListeners();

    final success = await ApiService.removeCartItem(cartItemId);
    if (!success) {
      _items.add(removed);
      notifyListeners();
    }
  }

  void clearCart() {
    _items = [];
    notifyListeners();
  }
}