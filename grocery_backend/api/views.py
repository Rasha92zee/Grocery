from rest_framework import viewsets, filters, status, generics, views 
from django_filters.rest_framework import DjangoFilterBackend # Added backend
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count
from .models import (
    MasterProduct, Shop, ShopInventory, 
    CartItem, Order, OrderItem, User, Favorite
)
from rest_framework.views import APIView
from .serializers import (
    MasterProductSerializer, InventorySerializer, CartSerializer, 
    ShopSerializer, OrderSerializer, FavoriteSerializer, ShopListingSerializer
)
from django.db import transaction

from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
import json

@csrf_exempt # This is needed to allow POST requests without CSRF token, but be careful in production!
def send_otp(request):
    if request.method == 'POST':
        # Your OTP logic here...
        return JsonResponse({'status': 'success', 'message': 'OTP sent'})
    return JsonResponse({"error": "Invalid request"}, status=400)

# 1. Master Catalog View - Now with Search and Category Filtering
class MasterCatalogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MasterProduct.objects.all()
    serializer_class = MasterProductSerializer
    
    # Enable filtering, searching, and ordering
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    
    # Exact match filters (e.g., ?category=Bakery)
    filterset_fields = ['category', 'brand']
    
    # Partial match search (e.g., ?search=brea)
    search_fields = ['name', 'brand', 'description']
    
    # Allow ordering by name or price
    ordering_fields = ['name']


# 2. Shop Inventory View
class ShopInventoryViewSet(viewsets.ModelViewSet):
    serializer_class = InventorySerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_authenticated and user.is_shop_owner:
            return ShopInventory.objects.filter(shop__owner=user).select_related('product')
        shop_id = self.request.query_params.get('shop_id')
        if shop_id:
            return ShopInventory.objects.filter(shop_id=shop_id)
        return ShopInventory.objects.all()

    def perform_create(self, serializer):
        shop = Shop.objects.get(owner=self.request.user)
        serializer.save(shop=shop)
    
class CartViewSet(viewsets.ModelViewSet):
    serializer_class = CartSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Only return cart items belonging to the logged-in user
        return CartItem.objects.filter(user=self.request.user)

    def create(self, request, *args, **kwargs):
        inventory_id = request.data.get('inventory_id')
        quantity = int(request.data.get('quantity', 1))

        # Check if item exists in shop inventory
        try:
            inventory_item = ShopInventory.objects.get(id=inventory_id)
        except ShopInventory.DoesNotExist:
            return Response({"error": "Product not found in shop"}, status=status.HTTP_404_NOT_FOUND)

        # Update quantity if item already in cart, else create new
        cart_item, created = CartItem.objects.get_or_create(
            user=request.user,
            inventory_item=inventory_item,
            defaults={'quantity': quantity}
        )

        if not created:
            cart_item.quantity += quantity
            cart_item.save()

        return Response({"message": "Added to cart"}, status=status.HTTP_201_CREATED)

class CreateShopView(generics.CreateAPIView):
    serializer_class = ShopSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        # Check if this user already owns a shop
        if Shop.objects.filter(owner=request.user).exists():
            return Response(
                {"error": "You already have a shop registered."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        # This automatically links the new shop to the logged-in user
        serializer.save(owner=self.request.user)
        
        # After creating the shop, we ensure the flag is definitely True
        self.request.user.is_shop_owner = True
        self.request.user.save()

class CheckoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # 1. Get items for this specific user
        user_cart = CartItem.objects.filter(user=request.user)
        
        if not user_cart.exists():
            return Response({"error": "Cart is empty for this user"}, status=400)

        # 2. Use an Atomic Transaction (All or nothing)
        with transaction.atomic():
            # Group items by shop
            shops_in_cart = user_cart.values_list('inventory_item__shop', flat=True).distinct()
            created_orders = []

            for shop_id in shops_in_cart:
                shop = Shop.objects.get(id=shop_id)
                items_for_this_shop = user_cart.filter(inventory_item__shop=shop)
                fulfillments = request.data.get('fulfillments', {})
                shop_fulfillment = fulfillments.get(shop.shop_name, {})
                
                # Calculate total
                total = sum(item.inventory_item.price * item.quantity for item in items_for_this_shop)

                # Create the Order
                order = Order.objects.create(
                    customer=request.user,
                    shop=shop,
                    total_price=total,
                    status='PENDING',
                    fulfillment_type=shop_fulfillment.get('fulfillment_type', 'DELIVERY'),
                    delivery_address=shop_fulfillment.get('delivery_address', ''),
                    pickup_slot=shop_fulfillment.get('pickup_slot', ''),
                )

                # Create the OrderItems
                for item in items_for_this_shop:
                    OrderItem.objects.create(
                        order=order,
                        product=item.inventory_item.product,
                        quantity=item.quantity,
                        price_at_time_of_order=item.inventory_item.price
                    )
                created_orders.append(order.id)

            # 3. Clear the cart ONLY after orders are created
            user_cart.delete()

        return Response({
            "message": "Order placed successfully", 
            "order_ids": created_orders
        }, status=status.HTTP_201_CREATED)
    
class ShopOrderUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, order_id):
        user = request.user
        # Ensure only the owner of the shop linked to this order can update it
        try:
            if user.is_shop_owner:
                order = Order.objects.get(id=order_id, shop__owner=user)
            else:
                order = Order.objects.get(id=order_id, customer=user)
        except Order.DoesNotExist:
            return Response({"error": "Order not found or unauthorized"}, status=404)

        new_status = request.data.get('status')

        if new_status == 'CANCELLED' and order.status != 'PENDING':
            return Response({"error": "Only pending orders can be cancelled"}, status=400)

        if not user.is_shop_owner:
            if new_status != 'CANCELLED':
                return Response({"error": "Customers can only cancel orders"}, status=403)
            if order.status != 'PENDING':
                return Response({"error": "Only pending orders can be cancelled"}, status=400)

        if new_status in dict(Order.STATUS_CHOICES):
            order.status = new_status
            order.save()
            return Response({"message": f"Order status updated to {new_status}"})
        
        return Response({"error": "Invalid status"}, status=400)
    
class OrderListView(generics.ListAPIView):
    serializer_class = OrderSerializer # We'll create this next
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        #return Order.objects.all() #for exception handlling
        user = self.request.user
        if user.is_shop_owner:
            # Show orders belonging to the shop owned by this user
            return Order.objects.filter(shop__owner=user).order_by('-created_at')
        # Otherwise, show orders placed by this customer
        return Order.objects.filter(customer=user).order_by('-created_at')

class FavoriteToggleView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, product_id):
        try:
            inventory_item = MasterProduct.objects.get(id=product_id)
        except MasterProduct.DoesNotExist:
            return Response({"error": "Item not found"}, status=404)

        favorite, created = Favorite.objects.get_or_create(
            user=request.user, 
            product=inventory_item
        )

        if not created:
            favorite.delete()
            return Response({"message": "Removed from favorites", "is_favorite": False})
        
        return Response({"message": "Added to favorites", "is_favorite": True}, status=201)

class FavoriteListView(generics.ListAPIView):
    serializer_class = FavoriteSerializer 
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Return all inventory items favorited by this user
        return Favorite.objects.filter(user=self.request.user).select_related('product')
    
class RegisterView(views.APIView):
    def post(self, request):
        data = request.data
        phone = data.get('phone_number')
        password = data.get('password')
        full_name = data.get('full_name')
        is_owner = data.get('is_shop_owner', False)

        if User.objects.filter(phone_number=phone).exists():
            return Response({"error": "Phone number already registered"}, status=status.HTTP_400_BAD_REQUEST)

        # Create the User
        user = User.objects.create_user(
            phone_number=phone,
            password=password,
            full_name=full_name,
            is_shop_owner=is_owner,
            is_customer=not is_owner # If they are an owner, they aren't 'just' a customer
        )

        # If they are a shop owner, initialize their shop
        if is_owner:
            Shop.objects.create(
                owner=user, 
                name=f"{full_name}'s Grocery Store",
                is_active=False # Keep inactive until admin verifies them
            )

        return Response({"message": "Account created successfully"}, status=status.HTTP_201_CREATED)
    
class ProductShopsView(generics.ListAPIView):
    serializer_class = ShopListingSerializer

    def get_queryset(self):
        product_id = self.kwargs['product_id']
        return ShopInventory.objects.filter(
            product__id=product_id,
            is_available=True,
            stock_quantity__gt=0,
        ).select_related('shop').order_by('price')
    
class CartItemUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        try:
            item = CartItem.objects.get(id=pk, user=request.user)
        except CartItem.DoesNotExist:
            return Response({"error": "Item not found"}, status=404)
        quantity = request.data.get('quantity')
        if quantity is not None:
            item.quantity = int(quantity)
            item.save()
            return Response({"message": "Updated"})
        return Response({"error": "quantity required"}, status=400)
    
class ShopListView(generics.ListAPIView):
    serializer_class = ShopSerializer
    queryset = Shop.objects.annotate(
        product_count=Count('inventory')
    ).order_by('shop_name')

# views.py — My Shop endpoints for the seller
class MyShopView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            shop = Shop.objects.get(owner=request.user)
            return Response(ShopSerializer(shop).data)
        except Shop.DoesNotExist:
            return Response({"error": "No shop found"}, status=404)

    def patch(self, request):
        try:
            shop = Shop.objects.get(owner=request.user)
        except Shop.DoesNotExist:
            return Response({"error": "No shop found"}, status=404)
        serializer = ShopSerializer(shop, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)