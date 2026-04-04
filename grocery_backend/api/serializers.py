from rest_framework import serializers
from .models import MasterProduct, Shop, ShopInventory, CartItem, Order, OrderItem, User, Favorite

class MasterProductSerializer(serializers.ModelSerializer):
    image_url = serializers.ImageField(use_url=True)
    display_weight = serializers.ReadOnlyField(source='formatted_weight')
    nearest_shop_lat = serializers.SerializerMethodField()
    nearest_shop_lng = serializers.SerializerMethodField()

    def get_nearest_shop_lat(self, obj):
        shop = obj.shopinventory_set.filter(
            is_available=True, shop__latitude__isnull=False
        ).select_related('shop').first()
        return shop.shop.latitude if shop else None

    def get_nearest_shop_lng(self, obj):
        shop = obj.shopinventory_set.filter(
            is_available=True, shop__longitude__isnull=False
        ).select_related('shop').first()
        return shop.shop.longitude if shop else None

    class Meta:
        model = MasterProduct
        fields = '__all__'

class InventorySerializer(serializers.ModelSerializer):
    product_details = MasterProductSerializer(source='product', read_only=True)

    class Meta:
        model = ShopInventory
        fields = ['id', 'price', 'stock_quantity', 'is_available', 'product_details', 
                  'product']

class CartSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='inventory_item.product.name')
    price = serializers.ReadOnlyField(source='inventory_item.price')
    shop_name = serializers.ReadOnlyField(source='inventory_item.shop.shop_name')
    product_image = serializers.SerializerMethodField()

    class Meta:
        model = CartItem
        fields = ['id', 'inventory_item', 'product_name', 'price', 'shop_name', 'quantity', 'product_image']

    def get_product_image(self, obj):
        request = self.context.get('request')
        image = obj.inventory_item.product.image_url
        if image and request:
            return request.build_absolute_uri(image.url)
        return ''

class ShopSerializer(serializers.ModelSerializer):
    class Meta:
        model = Shop
        # We don't include 'owner' because it's handled automatically in the view
        fields = ['id', 'shop_name', 'address', 'shop_slug', 'latitude', 'longitude', 'description']
        read_only_fields = ['shop_slug'] # The API will show it, but won't require it as input

class ShopListingSerializer(serializers.ModelSerializer):
    shop_name = serializers.ReadOnlyField(source='shop.shop_name')
    shop_slug = serializers.ReadOnlyField(source='shop.shop_slug')

    class Meta:
        model = ShopInventory
        fields = ['id', 'shop_name', 'shop_slug', 'price', 'stock_quantity', 'is_available']

class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')
    class Meta:
        model = OrderItem
        fields = ['product_name', 'quantity', 'price_at_time_of_order']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    customer_name = serializers.ReadOnlyField(source='customer.full_name')
    shop_name = serializers.ReadOnlyField(source='shop.shop_name')
    shop_address = serializers.ReadOnlyField(source='shop.address')

    class Meta:
        model = Order
        fields = ['id', 'customer_name', 'shop_name', 'total_price', 'status', 'created_at',
                   'items', 'fulfillment_type', 'delivery_address', 'pickup_slot', 'shop_address']

class FavoriteSerializer(serializers.ModelSerializer):
    product = MasterProductSerializer(read_only=True)
    
    class Meta:
        model = Favorite
        fields = ['id', 'product', 'created_at']

class ShopSerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(read_only=True) 

    class Meta:
        model = Shop
        fields = ['id', 'shop_name', 'address', 'shop_slug', 
                  'product_count', 'is_active','latitude', 'longitude',]
        read_only_fields = ['shop_slug']