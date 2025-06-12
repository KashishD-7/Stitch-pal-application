from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import *
from django.contrib.auth.hashers import make_password


class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewUser
        fields = ("user_id", "full_name", "email_address", "phone_number", "user_type")


class LoginSerializer ( serializers.Serializer ) :
    email_address = serializers.EmailField ()
    password = serializers.CharField ( write_only=True )

    def validate ( self , data ) :
        email = data.get ( "email_address" )
        password = data.get ( "password" )

        user = authenticate ( email_address=email , password=password )
        if user is None :
            raise serializers.ValidationError ( "Invalid email or password" )
        if not user.is_active :
            raise serializers.ValidationError ( "User account is disabled" )

        return user


class NewUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewUser
        fields = '__all__'

    def validate_password(self, value):
        """Hash password before saving"""
        return make_password(value)


class OrderCustomizationSerializer2 ( serializers.ModelSerializer ) :
    class Meta :
        model = OrderCustomization
        fields = '__all__'


class OrderCustomizationSerializer(serializers.ModelSerializer):
    order_name = serializers.CharField(source='order.customer_name', read_only=True)

    class Meta:
        model = OrderCustomization
        fields = [
            'id', 'order_name', 'fabric_choice', 'style_preferences',
            'color_options', 'additional_details', 'created_at'
        ]    


class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = '__all__'  # Ensure 'customer' is included
        read_only_fields = ('vendor', 'customer')

class OrderDropdownSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ['id', 'customer_name'] 

class MeasurementSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()
    order_details = OrderDropdownSerializer(source='order', read_only=True)
    order = serializers.PrimaryKeyRelatedField(queryset=Order.objects.all(), write_only=True)

    class Meta:
        model = Measurement
        fields = '__all__'

    def get_customer_name(self, obj):
        if obj.order and obj.order.customer:
            return obj.order.customer.full_name
        return None    





             


class TailorShopSerializer(serializers.ModelSerializer):
    class Meta:
        model = TailorShop
        fields = '__all__'


class VendorShopSerializer(serializers.ModelSerializer):
    class Meta:
        model = VendorShop
        fields = '__all__'



class PasswordResetRequestSerializer(serializers.Serializer):
    email_address = serializers.EmailField(required=False)
    phone_number = serializers.CharField(required=False)

    def validate(self, data):
        if not data.get('email_address') and not data.get('phone_number'):
            raise serializers.ValidationError("Either email address or phone number is required.")
        return data

class VerifyOTPSerializer(serializers.Serializer):
    email_address = serializers.EmailField(required=False)
    phone_number = serializers.CharField(required=False)
    otp = serializers.CharField()

class SetNewPasswordSerializer(serializers.Serializer):
    email_address = serializers.EmailField(required=False)
    phone_number = serializers.CharField(required=False)
    reset_token = serializers.UUIDField()
    new_password = serializers.CharField(min_length=8)
    
    def validate_new_password(self, value):
        """
        Validate the new password (you can add password complexity requirements here)
        """
        # Example of a basic password validation
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long")
        return value
    

class ShopImageUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewUser
        fields = ['shop_name', 'image']   


class ShopDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewUser
        fields = ['shop_name', 'address', 'location', 'image']        



class AppointmentSerializer(serializers.ModelSerializer):
    vendor_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Appointment
        fields = [
            'id', 'date', 'time_slot', 'name', 'contact', 
            'remark', 'created_at', 'vendor', 'vendor_name'
        ]
        
    def get_vendor_name(self, obj):
        if obj.vendor:
            # Return the name of the vendor (adjust field names according to your User model)
            return obj.vendor.full_name or obj.vendor.email_address
        return None

class VendorSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewUser
        fields = ['user_id', 'full_name', 'shop_name']  # Adjust fields as needed                