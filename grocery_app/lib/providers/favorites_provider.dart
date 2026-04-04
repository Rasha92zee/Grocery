import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  // Set of product IDs that are currently favourited
  final Set<int> _favoriteIds = {};
  List<MasterProduct> _favoriteProducts = [];
  bool isLoading = false;

  Set<int> get favoriteIds => _favoriteIds;
  List<MasterProduct> get favoriteProducts => _favoriteProducts;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  // ─── Load favourites from backend ─────────────────────────────────────────

  Future<void> loadFavorites() async {
    isLoading = true;
    notifyListeners();

    try {
      final products = await ApiService.fetchFavorites();
      _favoriteProducts = products;
      _favoriteIds.clear();
      for (final p in products) {
        _favoriteIds.add(p.id);
      }
    } catch (e) {
      debugPrint("FavoritesProvider loadFavorites error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // ─── Toggle favourite (optimistic UI update) ──────────────────────────────

  Future<void> toggleFavorite(MasterProduct product) async {
    final wasLiked = _favoriteIds.contains(product.id);

    // 1. Optimistic update — feels instant to the user
    if (wasLiked) {
      _favoriteIds.remove(product.id);
      _favoriteProducts.removeWhere((p) => p.id == product.id);
    } else {
      _favoriteIds.add(product.id);
      _favoriteProducts.add(product);
    }
    notifyListeners();

    // 2. Call the backend
    final result = await ApiService.toggleFavorite(product.id);

    // 3. If backend call failed, roll back the optimistic update
    if (result == null) {
      if (wasLiked) {
        _favoriteIds.add(product.id);
        _favoriteProducts.add(product);
      } else {
        _favoriteIds.remove(product.id);
        _favoriteProducts.removeWhere((p) => p.id == product.id);
      }
      notifyListeners();
    }
  }
}
