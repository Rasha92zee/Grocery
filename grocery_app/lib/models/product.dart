class MasterProduct {
  final int id;
  final String name;
  final double price;
  final double referencePrice;
  final String photo;
  final double weightValue;
  final String unitType;
  final String displayWeight;
  final String category;
  final String description;
  final String brand;
  // ✅ Nearest shop coords — populated from API for distance display
  final double? nearestShopLat;
  final double? nearestShopLng;
  final double? nearestShopDistance;

  MasterProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.referencePrice,
    required this.photo,
    required this.weightValue,
    required this.unitType,
    required this.displayWeight,
    required this.category,
    required this.description,
    required this.brand,
    this.nearestShopLat,
    this.nearestShopLng,
    this.nearestShopDistance,
  });

  factory MasterProduct.fromJson(Map<String, dynamic> json) {
    return MasterProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      photo: json['image_url'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      referencePrice: double.tryParse(json['reference_price']?.toString() ?? '0.0') ?? 0.0,
      weightValue: double.tryParse(json['weight_value']?.toString() ?? '0.0') ?? 0.0,
      unitType: json['unit_type'] ?? 'g',
      displayWeight: "${json['weight_value'] ?? '0'}${json['unit_type'] ?? 'g'}",
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      nearestShopLat: double.tryParse(json['nearest_shop_lat']?.toString() ?? ''),
      nearestShopLng: double.tryParse(json['nearest_shop_lng']?.toString() ?? ''),
    );
  }
}

class ShopListing {
  final int inventoryId;
  final String shopName;
  final String shopSlug;
  final double price;
  final int stockQuantity;
  final bool isAvailable;

  ShopListing({
    required this.inventoryId,
    required this.shopName,
    required this.shopSlug,
    required this.price,
    required this.stockQuantity,
    required this.isAvailable,
  });

  factory ShopListing.fromJson(Map<String, dynamic> json) {
    return ShopListing(
      inventoryId: json['id'] ?? 0,
      shopName: json['shop_name'] ?? '',
      shopSlug: json['shop_slug'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      stockQuantity: json['stock_quantity'] ?? 0,
      isAvailable: json['is_available'] ?? false,
    );
  }
}

class ShopInventoryItem {
  final int id;
  final int productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int stockQuantity;
  final bool isAvailable;

  ShopInventoryItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.stockQuantity,
    required this.isAvailable,
  });

  factory ShopInventoryItem.fromJson(Map<String, dynamic> json) {
    final details = json['product_details'] as Map<String, dynamic>? ?? {};
    return ShopInventoryItem(
      id: json['id'] ?? 0,
      productId: details['id'] ?? 0,
      productName: details['name'] ?? '',
      imageUrl: details['image_url'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stockQuantity: json['stock_quantity'] ?? 0,
      isAvailable: json['is_available'] ?? true,
    );
  }
}