from django.urls import path, include 
from rest_framework.routers import DefaultRouter
from .views import (
    CartItemUpdateView, FavoriteToggleView, MasterCatalogViewSet, MyShopView, ProductShopsView, ShopInventoryViewSet, 
    CartViewSet, CreateShopView, ShopListView, ShopOrderUpdateView, 
    CheckoutView, OrderListView, FavoriteListView
)
from .auth_views import SendOTP, VerifyOTP

router = DefaultRouter()
router.register(r'shop-inventory', ShopInventoryViewSet, basename='shopinventory')
router.register(r'cart', CartViewSet, basename='cart')
router.register(r'products', MasterCatalogViewSet, basename='masterproduct')

urlpatterns = [
    # Router URLs (Only include this ONCE)
    path('', include(router.urls)),
    
    # Auth Endpoints
    path('auth/send-otp/', SendOTP.as_view(), name='send_otp'),
    path('auth/verify-otp/', VerifyOTP.as_view(), name='verify_otp'),
    
    # Shop & Order Endpoints
    path('create-shop/', CreateShopView.as_view(), name='create-shop'),
    path('checkout/', CheckoutView.as_view(), name='checkout'),
    path('orders/', OrderListView.as_view(), name='order-list'),
    path('orders/<int:order_id>/update/', ShopOrderUpdateView.as_view(), name='update-order'),
    
    # Favorites Endpoints
    path('favorites/', FavoriteListView.as_view(), name='favorite-list'),
    path('favorites/toggle/<int:product_id>/', FavoriteToggleView.as_view(), name='favorite-toggle'),

    path('products/<int:product_id>/shops/', ProductShopsView.as_view(), name='product-shops'),
    path('cart/<int:pk>/', CartItemUpdateView.as_view(), name='cart-item-update'),
    path('shops/', ShopListView.as_view(), name='shop-list'),
    path('my-shop/', MyShopView.as_view(), name='my-shop'),
]