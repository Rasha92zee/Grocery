class CartItemModel {
  final int id;
  final int inventoryId;
  final String productName;
  final String productImage;
  final String shopName;
  final double price;
  int quantity;

  CartItemModel({
    required this.id,
    required this.inventoryId,
    required this.productName,
    required this.productImage,
    required this.shopName,
    required this.price,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? 0,
      inventoryId: json['inventory_item'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      shopName: json['shop_name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 1,
    );
  }
}

class CartGroup {
  final String shopName;
  final List<CartItemModel> items;
  CartGroup({required this.shopName, required this.items});
  double get shopTotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);
}

class OrderModel {
  final int id;
  final String shopName;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final String fulfillmentType;   // 'DELIVERY' or 'PICKUP'
  final String deliveryAddress;
  final String pickupSlot;
  final String? shopAddress;      // for map navigation (seller side)

  OrderModel({
    required this.id,
    required this.shopName,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.items,
    this.fulfillmentType = 'DELIVERY',
    this.deliveryAddress = '',
    this.pickupSlot = '',
    this.shopAddress,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      shopName: json['shop_name'] ?? '',
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'PENDING',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItemModel.fromJson(i))
          .toList(),
      fulfillmentType: json['fulfillment_type'] ?? 'DELIVERY',
      deliveryAddress: json['delivery_address'] ?? '',
      pickupSlot: json['pickup_slot'] ?? '',
      shopAddress: json['shop_address'],
    );
  }
}

class OrderItemModel {
  final String productName;
  final int quantity;
  final double priceAtOrder;

  OrderItemModel({
    required this.productName,
    required this.quantity,
    required this.priceAtOrder,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      priceAtOrder: double.tryParse(json['price_at_time_of_order']?.toString() ?? '0') ?? 0.0,
    );
  }
}