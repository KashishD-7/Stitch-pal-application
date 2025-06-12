from django.db import models
from django.contrib.auth.hashers import make_password
from django.contrib.auth.models import User
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.conf import settings
import random
from django.utils.timezone import now
import uuid



class CustomUserManager(BaseUserManager):
    def create_user(self, email_address, password=None, **extra_fields):
        """Create and return a regular user with an email and password"""
        if not email_address:
            raise ValueError(_("The Email field must be set"))
        email_address = self.normalize_email(email_address)
        extra_fields.setdefault("is_active", True)
        user = self.model(email_address=email_address, **extra_fields)
        user.set_password(password)  # Hash the password
        user.save(using=self._db)
        return user

    def create_superuser(self, email_address, password=None, **extra_fields):
        """Create and return a superuser"""
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email_address, password, **extra_fields)


class NewUser(AbstractBaseUser, PermissionsMixin):
    GENDER_CHOICES = [
        ('Male', 'Male'),
        ('Female', 'Female'),
        ('Other', 'Other'),
    ]

    USER_TYPE_CHOICES = [
        ('Tailor', 'Tailor'),
        ('Vendor', 'Vendor'),
    ]

    user_id = models.AutoField(primary_key=True)
    otp = models.CharField(max_length=6, blank=True, null=True)  # Field to store OTP
    image = models.ImageField(upload_to="user_images", default="")
    full_name = models.CharField(max_length=255)
    email_address = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
    shop_name = models.CharField(max_length=255, null=True, blank=True, default="")
    user_type = models.CharField(max_length=10, choices=USER_TYPE_CHOICES, default='Tailor')
    created_at = models.DateTimeField(auto_now_add=True)
    address = models.TextField(default="")
    pincode = models.CharField(max_length=50, default="")
    address_line_1 = models.TextField(default="")
    address_line_2 = models.TextField(default="")
    landmark = models.TextField(default="")
    location = models.CharField(max_length=300, null=True, blank=True, default="")
    business_hours = models.TextField(null=True, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = CustomUserManager()

    USERNAME_FIELD = "email_address"
    REQUIRED_FIELDS = ["full_name", "phone_number"]

    def __str__(self):
        return f"{self.full_name} ({self.user_type})"
    

class PasswordResetOTP(models.Model):
    user = models.ForeignKey(NewUser, on_delete=models.CASCADE, related_name='password_reset_otps')
    otp = models.CharField(max_length=8)
    reset_token = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    
    def __str__(self):
        return f"Password Reset OTP for {self.user.email_address}"    


class TailorShop(models.Model):
    shop_name = models.CharField(max_length=255)
    address = models.TextField()
    latitude = models.CharField(max_length=50, blank=True, null=True)  # String to allow flexibility
    longitude = models.CharField(max_length=50, blank=True, null=True)  # String to allow flexibility
    business_hours = models.TextField()
    shop_photo = models.ImageField(upload_to="shop_photos/", blank=True, null=True)

    def __str__(self):
        return self.shop_name


class VendorShop(models.Model):
    shop_name = models.CharField(max_length=255)
    address = models.TextField()
    latitude = models.CharField(max_length=50, blank=True, null=True)  # String to allow flexibility
    longitude = models.CharField(max_length=50, blank=True, null=True)  # String to allow flexibility
    business_hours = models.TextField()
    shop_photo = models.ImageField(upload_to="shop_photos/", blank=True, null=True)

    def __str__(self):
        return self.shop_name


class Order ( models.Model ) :
    STATUS_CHOICES = [
        ("Pending" , "Pending") ,
        ("In Progress" , "In Progress") ,
        ("Completed" , "Completed") ,
        ("Canceled" , "Canceled") ,
    ]

    DECISION_CHOICES = [
        ("Pending", "Pending"),   # default
        ("Accepted", "Accepted"),
        ("Declined", "Declined"),
    ]

    customer = models.ForeignKey (settings.AUTH_USER_MODEL, on_delete=models.CASCADE , related_name="orders" )
    vendor = models.ForeignKey (settings.AUTH_USER_MODEL , on_delete=models.SET_NULL , null=True , blank=True ,
                                 related_name="vendor_orders" )
    tailor = models.ForeignKey (settings.AUTH_USER_MODEL, on_delete=models.SET_NULL , null=True , blank=True ,
                                 related_name="tailor_orders" )
    customer_name = models.CharField ( max_length=255 )
    contact_number = models.CharField ( max_length=20 )
    clothing_types = models.TextField ()  # Store selected clothing types as a comma-separated string
    order_photo = models.ImageField ( upload_to="orders/" , blank=True , null=True )
    additional_instructions = models.TextField ( blank=True , null=True )
    price = models.DecimalField ( max_digits=10 , decimal_places=2 )
    status = models.CharField ( max_length=20 , choices=STATUS_CHOICES , default="Pending" )
    is_accepted = models.CharField(max_length=10, choices=DECISION_CHOICES, default="Pending")
    created_at = models.DateTimeField ( auto_now_add=True )

    def __str__ ( self ) :
        return f"Order {self.id} - {self.customer_name}"


class OrderCustomization(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="customizations")
    fabric_choice = models.CharField(max_length=255, blank=True, null=True)
    style_preferences = models.TextField(blank=True, null=True)
    color_options = models.CharField(max_length=100, blank=True, null=True)
    additional_details = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Customization for Order {self.order.id}"

    # CRUD Methods
    @classmethod
    def add_customization(cls, order_id, fabric_choice, style_preferences, color_options, additional_details):
        order = Order.objects.get(id=order_id)
        customization = cls.objects.create(
            order=order,
            fabric_choice=fabric_choice,
            style_preferences=style_preferences,
            color_options=color_options,
            additional_details=additional_details
        )
        return customization

    def edit_customization(self, fabric_choice, style_preferences, color_options, additional_details):
        self.fabric_choice = fabric_choice
        self.style_preferences = style_preferences
        self.color_options = color_options
        self.additional_details = additional_details
        self.save()
        return self

    def delete_customization(self):
        self.delete()


class Measurement ( models.Model ) :
    order = models.OneToOneField("Order", on_delete=models.CASCADE, related_name="measurement", null=True, blank=True)
    chest = models.FloatField ( null=True , blank=True )
    waist = models.FloatField ( null=True , blank=True )
    inseam = models.FloatField ( null=True , blank=True )
    shoulders = models.FloatField ( null=True , blank=True )
    sleeve_length = models.FloatField ( null=True , blank=True )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__ ( self ) :
        return f"Measurements for {self.order}"

    # CRUD Methods
    @classmethod
    def add_measurement(cls, customer_id, chest, waist, inseam, shoulders, sleeve_length):
        measurement = cls.objects.create(
            customer_id=customer_id,
            chest=chest,
            waist=waist,
            inseam=inseam,
            shoulders=shoulders,
            sleeve_length=sleeve_length
        )
        return measurement

    def edit_measurement(self, chest, waist, inseam, shoulders, sleeve_length):
        self.chest = chest
        self.waist = waist
        self.inseam = inseam
        self.shoulders = shoulders
        self.sleeve_length = sleeve_length
        self.save()
        return self

    def delete_measurement(self):
        self.delete()
        


class Appointment(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='appointments', default=11)
    vendor = models.ForeignKey(NewUser, on_delete=models.CASCADE, related_name='appointments_as_vendor', null=True)
    date = models.DateField()  # Date of the appointment
    time_slot = models.CharField(max_length=20)  # Time slot for the appointment
    name = models.CharField(max_length=255)  # Name of the person booking the appointment
    contact = models.CharField(max_length=20)  # Contact number
    remark = models.TextField(blank=True, null=True)  # Additional remarks (optional)
    created_at = models.DateTimeField(auto_now_add=True)  # Timestamp for record creation

    def __str__(self):
        return f"Appointment with {self.name} on {self.date} at {self.time_slot}"      



class OTPVerification(models.Model):
    user = models.OneToOneField(NewUser, on_delete=models.CASCADE)
    otp = models.CharField(max_length=6, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def generate_otp(self):
        self.otp = str(random.randint(100000, 999999))
        self.created_at = now()  # Update timestamp
        self.save()        


        