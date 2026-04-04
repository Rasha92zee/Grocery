class ShopModel {
  final int id;
  final String shopName;
  final String address;
  final String shopSlug;
  final int productCount;
  final double? latitude;
  final double? longitude;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.address,
    required this.shopSlug,
    required this.productCount,
    this.latitude,
    this.longitude,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? 0,
      shopName: json['shop_name'] ?? '',
      address: json['address'] ?? '',
      shopSlug: json['shop_slug'] ?? '',
      productCount: json['product_count'] ?? 0,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }
}