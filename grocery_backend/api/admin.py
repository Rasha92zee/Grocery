from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.safestring import mark_safe
from .models import User, MasterProduct, Shop, ShopInventory, CartItem, Favorite, Order, OrderItem


# ─── SITE BRANDING ────────────────────────────────────────────────────────────

admin.site.site_header = "Berry Basket Admin"
admin.site.site_title  = "Berry Basket"
admin.site.index_title = "Store Management Dashboard"


def badge(label, color):
    """Safe badge helper — no format_html, no None risk."""
    return mark_safe(
        f'<span style="color:#fff;background:{color};padding:2px 10px;'
        f'border-radius:10px;font-size:11px;">{label}</span>'
    )


# ─── USER ─────────────────────────────────────────────────────────────────────

class MyUserAdmin(UserAdmin):
    ordering        = ('phone_number',)
    list_display    = ('phone_number', 'full_name', 'role_badge', 'is_active', 'is_staff')
    list_filter     = ('is_shop_owner', 'is_active', 'is_staff')
    search_fields   = ('phone_number', 'full_name')
    readonly_fields = ()

    fieldsets = (
        (None, {'fields': ('phone_number', 'password')}),
        ('Personal Info', {'fields': ('full_name',)}),
        ('Permissions', {'fields': ('is_shop_owner', 'is_customer', 'is_active', 'is_staff', 'is_superuser')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone_number', 'full_name', 'password1', 'password2', 'is_shop_owner'),
        }),
    )

    @admin.display(description='Role')
    def role_badge(self, obj):
        if obj.is_staff:
            return badge('Admin', '#6366f1')
        if obj.is_shop_owner:
            return badge('Shop Owner', '#f59e0b')
        return badge('Customer', '#16a34a')


# ─── MASTER PRODUCT ───────────────────────────────────────────────────────────

class MasterProductAdmin(admin.ModelAdmin):
    list_display    = ('product_image', 'name', 'category', 'brand', 'weight_display', 'reference_price')
    list_filter     = ('category', 'brand')
    search_fields   = ('name', 'brand', 'description')
    ordering        = ('category', 'name')
    readonly_fields = ('product_image_large',)

    fieldsets = (
        ('Product Info', {'fields': ('name', 'brand', 'category', 'description')}),
        ('Weight', {'fields': ('weight_value', 'unit_type')}),
        ('Pricing', {'fields': ('reference_price',)}),
        ('Media', {'fields': ('image_url', 'product_image_large')}),
    )

    @admin.display(description='Image')
    def product_image(self, obj):
        if obj.image_url:
            url = obj.image_url.url
            return mark_safe(f'<img src="{url}" style="height:40px;width:40px;object-fit:contain;border-radius:6px;" />')
        return '—'

    @admin.display(description='Preview')
    def product_image_large(self, obj):
        if obj.image_url:
            url = obj.image_url.url
            return mark_safe(f'<img src="{url}" style="height:120px;object-fit:contain;" />')
        return '—'

    @admin.display(description='Weight')
    def weight_display(self, obj):
        return f"{obj.weight_value or 0}{obj.unit_type or ''}"


# ─── SHOP ─────────────────────────────────────────────────────────────────────

class ShopAdmin(admin.ModelAdmin):
    list_display    = ('shop_name', 'owner_phone', 'owner_name', 'shop_slug', 'address', 'is_active')
    list_filter     = ()
    search_fields   = ('shop_name', 'owner__phone_number', 'owner__full_name')
    ordering        = ('shop_name',)
    readonly_fields = ('shop_slug',)
    list_editable = ['is_active']

    fieldsets = (
        (None, {
            'fields': ('owner', 'shop_name', 'address', 'latitude', 
                      'longitude', 'description', 'shop_slug', 'is_active')  
        }),
    )

    @admin.display(description='Owner Phone')
    def owner_phone(self, obj):
        return obj.owner.phone_number if obj.owner else '—'

    @admin.display(description='Owner Name')
    def owner_name(self, obj):
        return obj.owner.full_name if obj.owner else '—'


# ─── SHOP INVENTORY ───────────────────────────────────────────────────────────

class ShopInventoryAdmin(admin.ModelAdmin):
    list_display  = ('product_name', 'shop', 'price_display', 'stock_quantity', 'availability_badge')
    list_filter   = ('shop', 'is_available')
    search_fields = ('product__name', 'shop__shop_name')
    ordering      = ('shop', 'product__name')

    @admin.display(description='Product')
    def product_name(self, obj):
        return obj.product.name if obj.product else '—'

    @admin.display(description='Price')
    def price_display(self, obj):
        if obj.price is None:
            return '—'
        return mark_safe(f'<strong style="color:#16a34a;">₹{obj.price}</strong>')

    @admin.display(description='Available')
    def availability_badge(self, obj):
        if obj.is_available:
            return badge('In Stock', '#16a34a')
        return badge('Out of Stock', '#ef4444')


# ─── CART ITEM ────────────────────────────────────────────────────────────────

class CartItemAdmin(admin.ModelAdmin):
    list_display  = ('customer_phone', 'product_name', 'shop_name', 'quantity', 'line_total', 'added_at')
    list_filter   = ('inventory_item__shop',)
    search_fields = ('user__phone_number', 'inventory_item__product__name')
    ordering      = ('-added_at',)

    @admin.display(description='Customer')
    def customer_phone(self, obj):
        return obj.user.phone_number if obj.user else '—'

    @admin.display(description='Product')
    def product_name(self, obj):
        return obj.inventory_item.product.name if obj.inventory_item else '—'

    @admin.display(description='Shop')
    def shop_name(self, obj):
        return obj.inventory_item.shop.shop_name if obj.inventory_item else '—'

    @admin.display(description='Line Total')
    def line_total(self, obj):
        if obj.inventory_item and obj.inventory_item.price and obj.quantity:
            total = obj.inventory_item.price * obj.quantity
            return mark_safe(f'<strong style="color:#16a34a;">₹{total}</strong>')
        return '—'


# ─── FAVORITE ─────────────────────────────────────────────────────────────────

class FavoriteAdmin(admin.ModelAdmin):
    list_display    = ('customer_phone', 'product_name', 'product_category', 'created_at')
    list_filter     = ('product__category',)
    search_fields   = ('user__phone_number', 'product__name')
    ordering        = ('-created_at',)
    readonly_fields = ('created_at',)

    @admin.display(description='Customer')
    def customer_phone(self, obj):
        return obj.user.phone_number if obj.user else '—'

    @admin.display(description='Product')
    def product_name(self, obj):
        return obj.product.name if obj.product else '—'

    @admin.display(description='Category')
    def product_category(self, obj):
        return obj.product.category if obj.product else '—'


# ─── ORDER ITEM INLINE ────────────────────────────────────────────────────────

class OrderItemInline(admin.TabularInline):
    model           = OrderItem
    extra           = 0
    readonly_fields = ('product', 'quantity', 'price_at_time_of_order', 'line_total')
    can_delete      = False

    @admin.display(description='Line Total')
    def line_total(self, obj):
        if obj.price_at_time_of_order and obj.quantity:
            return f"₹{obj.price_at_time_of_order * obj.quantity}"
        return '—'


# ─── ORDER ────────────────────────────────────────────────────────────────────

class OrderAdmin(admin.ModelAdmin):
    list_display    = ('id', 'customer_phone', 'shop_name', 'total_price_display', 'status_badge', 'created_at')
    list_filter     = ('status', 'created_at', 'shop')
    search_fields   = ('customer__phone_number', 'customer__full_name', 'shop__shop_name')
    ordering        = ('-created_at',)
    readonly_fields = ('created_at',)
    inlines         = [OrderItemInline]

    @admin.display(description='Customer')
    def customer_phone(self, obj):
        return obj.customer.phone_number if obj.customer else '—'

    @admin.display(description='Shop')
    def shop_name(self, obj):
        return obj.shop.shop_name if obj.shop else '—'

    @admin.display(description='Total')
    def total_price_display(self, obj):
        if obj.total_price is None:
            return '—'
        return mark_safe(f'<strong style="color:#16a34a;">₹{obj.total_price}</strong>')

    @admin.display(description='Status')
    def status_badge(self, obj):
        colors = {
            'PENDING':   '#f59e0b',
            'PACKING':   '#3b82f6',
            'READY':     '#8b5cf6',
            'COMPLETED': '#16a34a',
        }
        color = colors.get(obj.status, '#6b7280')
        label = obj.get_status_display() or obj.status or '—'
        return badge(label, color)


# ─── ORDER ITEM ───────────────────────────────────────────────────────────────

class OrderItemAdmin(admin.ModelAdmin):
    list_display  = ('order_id', 'product_name', 'quantity', 'price_at_time_of_order', 'line_total')
    list_filter   = ('order__status', 'order__shop')
    search_fields = ('product__name', 'order__customer__phone_number')
    ordering      = ('-order__created_at',)

    @admin.display(description='Order #')
    def order_id(self, obj):
        return f"#{obj.order.id}" if obj.order else '—'

    @admin.display(description='Product')
    def product_name(self, obj):
        return obj.product.name if obj.product else '—'

    @admin.display(description='Line Total')
    def line_total(self, obj):
        if obj.price_at_time_of_order and obj.quantity:
            return mark_safe(f'<strong style="color:#16a34a;">₹{obj.price_at_time_of_order * obj.quantity}</strong>')
        return '—'


# ─── REGISTER ─────────────────────────────────────────────────────────────────

admin.site.register(User, MyUserAdmin)
admin.site.register(MasterProduct, MasterProductAdmin)
admin.site.register(Shop, ShopAdmin)
admin.site.register(ShopInventory, ShopInventoryAdmin)
admin.site.register(CartItem, CartItemAdmin)
admin.site.register(Favorite, FavoriteAdmin)
admin.site.register(Order, OrderAdmin)
admin.site.register(OrderItem, OrderItemAdmin)