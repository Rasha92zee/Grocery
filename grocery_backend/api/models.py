from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils.text import slugify

# 1. THE MANAGER (Handles creating users without a username)
class UserManager(BaseUserManager):
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError('The Phone Number field must be set')
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(phone_number, password, **extra_fields)

# 2. THE CUSTOM USER MODEL
class User(AbstractUser):
    username = None
    phone_number = models.CharField(max_length=15, unique=True)
    full_name = models.CharField(max_length=255, blank=True)
    
    # User roles
    is_shop_owner = models.BooleanField(default=False)
    is_customer = models.BooleanField(default=True) # Default for app sign-ups

    objects = UserManager()

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['full_name']

    def __str__(self):
        return f"{self.phone_number} ({'Shop Owner' if self.is_shop_owner else 'Customer'})"

# 3. MASTER CATALOG
class MasterProduct(models.Model):
    name = models.CharField(max_length=255)
    brand = models.CharField(max_length=100)
    image_url = models.ImageField(upload_to='product_photos/', null=True, blank=True)
    category = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    UNIT_CHOICES = [
        ('g', 'Grams'),
        ('kg', 'Kilograms'),
        ('ml', 'Milliliters'),
        ('l', 'Liters'),
        ('pcs', 'Pieces'),
    ]
    weight_value = models.DecimalField(max_digits=6, decimal_places=2, default=0.0)
    unit_type = models.CharField(max_length=5, choices=UNIT_CHOICES, default='g')
    reference_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True,
    help_text="Admin-set market reference price shown in catalog")

    def __str__(self):
        return f"{self.name} ({self.weight_value}{self.unit_type})"
# 4. SHOPS
class Shop(models.Model):
    owner = models.OneToOneField(User, on_delete=models.CASCADE)
    shop_name = models.CharField(max_length=255)
    address = models.TextField()
    shop_slug = models.SlugField(unique=True, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    is_active = models.BooleanField(default=False)

    

    def save(self, *args, **kwargs):
        if not self.shop_slug:
            # Creates a slug like "Organic Greens" -> "organic-greens"
            self.shop_slug = slugify(self.shop_name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.shop_name

# 5. SHOP INVENTORY
class ShopInventory(models.Model):
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name="inventory")
    product = models.ForeignKey(MasterProduct, on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock_quantity = models.IntegerField(default=0)
    is_available = models.BooleanField(default=True)

    class Meta:
        unique_together = ('shop', 'product')

# 6. FAVORITES
class Favorite(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="favorites")
    product = models.ForeignKey(MasterProduct, on_delete=models.CASCADE, related_name="favorited_by")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'product') # Prevents favoriting same item twice

# 7. CART
class CartItem(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="cart")
    # Note: We link to ShopInventory because price depends on the specific shop
    inventory_item = models.ForeignKey(ShopInventory, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    added_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.phone_number} - {self.inventory_item.product.name}"
    
# 8. ORDER
class Order(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('PACKING', 'Packing In Progress'),
        ('READY', 'Ready for Pickup'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]

    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name="orders")
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name="orders")
    total_price = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    fulfillment_type = models.CharField(max_length=10,
    choices=[('DELIVERY','Delivery'),('PICKUP','Pickup')], default='DELIVERY')
    delivery_address = models.TextField(blank=True, default='')
    pickup_slot = models.CharField(max_length=50, blank=True, default='')

# 9. ORDERITEM
class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey(MasterProduct, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField()
    price_at_time_of_order = models.DecimalField(
        max_digits=10, decimal_places=2
    )
    price_at_purchase = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=0.0
    )
    weight_at_purchase = models.CharField(
        max_length=20, 
        default="0g"
    )


