from rest_framework import generics , status
from rest_framework.response import Response
from rest_framework.views import APIView
import requests
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.db.models import Q
from django.core.mail import send_mail
from django.contrib.auth.decorators import login_required
from collections import OrderedDict
from rest_framework.permissions import AllowAny
from datetime import datetime
from rest_framework.permissions import IsAuthenticatedOrReadOnly
import json
from django.core.files.base import ContentFile
import base64
from .models import *
from .forms import *
from .serializers import *
from rest_framework.parsers import MultiPartParser, FormParser
import random
from django.contrib.auth import authenticate, login
from rest_framework.decorators import api_view, permission_classes
from django.contrib.auth.hashers import check_password
from rest_framework.decorators import action
from rest_framework import viewsets
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
import redis  # Using Redis for temporary OTP storage
from django.http import JsonResponse
from django.middleware.csrf import get_token
from django.views.decorators.csrf import csrf_exempt
import ssl
from twilio.rest import Client
from datetime import timedelta
from django.utils.timezone import now
from django.contrib.auth import get_user_model
from django.utils.crypto import get_random_string
from .serializers import PasswordResetRequestSerializer, VerifyOTPSerializer, SetNewPasswordSerializer
from django.utils import timezone
from django.core.mail import get_connection
from .custom_email_backend import send_otp_email
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
User = get_user_model()


# Function to send OTP via email
def send_otp_email(email, otp):
    subject = "Password Reset OTP"
    message = f"Your OTP for password reset is: {otp}. It is valid for 5 minutes."
    from_email = "sstichpal@gmail.com"  # Replace with your email
    send_mail(subject, message, from_email, [email])


r = redis.StrictRedis(host='localhost', port=6379, db=0, decode_responses=True)


def get_csrf_token(request):
    """
    This view will return the CSRF token for your Flutter app to use.
    """
    csrf_token = get_token(request)  # Get the CSRF token
    return JsonResponse({'csrf_token': csrf_token})


def send_otp_via_sms(phone_number):
    # Generate 6-digit OTP
    otp = str(random.randint(100000, 999999))
    
    # Initialize Twilio client
    client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
    
    # Send SMS
    message = client.messages.create(
        body=f"Your OTP for password reset is: {otp}. It is valid for 15 minutes.",
        from_=settings.TWILIO_PHONE_NUMBER,
        to=phone_number
    )
    
    return otp


# Then when sending email, you need to override connection:
def get_mailtrap_connection():
    return get_connection(
        host=settings.EMAIL_HOST,
        port=settings.EMAIL_PORT,
        username=settings.EMAIL_HOST_USER,
        password=settings.EMAIL_HOST_PASSWORD,
        use_tls=settings.EMAIL_USE_TLS,
        ssl_context=settings.EMAIL_SSL_CONTEXT,
    )


# 🔥 Send Email using Gmail SMTP
def send_otp_email_gmail(to_email, otp):
    smtp_server = 'smtp.gmail.com'
    smtp_port = 587
    smtp_user = 'sstichpal@gmail.com'  # your Gmail
    smtp_password = 'otqlpuwfmaaoyzsf'  # your App password

    subject = 'Your OTP Code'
    body = f'Your OTP code is: {otp}'

    msg = MIMEMultipart()
    msg['From'] = smtp_user
    msg['To'] = to_email
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.sendmail(smtp_user, to_email, msg.as_string())
        server.quit()
        print(f"OTP Email sent to {to_email}")
        return True
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False


# 🚀 Your view to request password reset
@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    serializer = PasswordResetRequestSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data.get('email_address')
        phone = serializer.validated_data.get('phone_number')

        try:
            if email:
                user = User.objects.get(email_address=email)
                method = 'email'
                recipient = email
            elif phone:
                user = User.objects.get(phone_number=phone)
                method = 'phone'
                recipient = phone
            else:
                return Response({'status': 'error', 'message': 'No valid identifier provided.'}, status=400)

            # 🔥 Generate and store OTP
            otp = str(random.randint(100000, 999999))
            PasswordResetOTP.objects.filter(user=user).delete()
            PasswordResetOTP.objects.create(
                user=user,
                otp=otp,
                reset_token=str(uuid.uuid4()),
                expires_at=timezone.now() + timedelta(minutes=15)
            )

            if method == 'email':
                success = send_otp_email_gmail(recipient, otp)
                if not success:
                    return Response({'status': 'error', 'message': 'Failed to send OTP email.'}, status=500)
            else:
                return Response({'status': 'error', 'message': 'SMS sending not implemented yet.'}, status=501)

            return Response({'status': 'success', 'message': f'OTP sent to your {method}'})

        except User.DoesNotExist:
            return Response({'status': 'error', 'message': 'No account found with this identifier.'}, status=404)

    return Response(serializer.errors, status=400)



@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    """
    Verify the submitted OTP using either email or phone number.
    """
    serializer = VerifyOTPSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data.get('email_address')
        phone = serializer.validated_data.get('phone_number')
        otp = serializer.validated_data['otp']
        
        try:
            if email:
                user = User.objects.get(email_address=email)
            elif phone:
                user = User.objects.get(phone_number=phone)
            else:
                return Response({'status': 'error', 'message': 'No valid identifier provided.'}, status=400)
        
        except User.DoesNotExist:
            return Response({'status': 'error', 'message': 'User not found'}, status=404)
        
        try:
            reset_otp = PasswordResetOTP.objects.get(user=user, otp=otp)
            if reset_otp.expires_at < timezone.now():
                reset_otp.delete()
                return Response({'status': 'error', 'message': 'OTP has expired'}, status=400)

            return Response({
                'status': 'success',
                'message': 'OTP verified successfully',
                'reset_token': reset_otp.reset_token
            }, status=200)
        
        except PasswordResetOTP.DoesNotExist:
            return Response({'status': 'error', 'message': 'Invalid OTP'}, status=400)

    return Response(serializer.errors, status=400)



@api_view(['POST'])
@permission_classes([AllowAny])
def set_new_password(request):
    """
    Set a new password using email or phone along with a valid reset_token.
    """
    serializer = SetNewPasswordSerializer(data=request.data)
    if serializer.is_valid():
        email = serializer.validated_data.get('email_address')
        phone = serializer.validated_data.get('phone_number')
        reset_token = serializer.validated_data['reset_token']
        new_password = serializer.validated_data['new_password']
        
        try:
            if email:
                user = User.objects.get(email_address=email)
            elif phone:
                user = User.objects.get(phone_number=phone)
            else:
                return Response({'status': 'error', 'message': 'No valid identifier provided.'}, status=400)
        
        except User.DoesNotExist:
            return Response({'status': 'error', 'message': 'User not found'}, status=404)

        try:
            reset_otp = PasswordResetOTP.objects.get(user=user, reset_token=reset_token)
            if reset_otp.expires_at < timezone.now():
                reset_otp.delete()
                return Response({'status': 'error', 'message': 'Reset token has expired'}, status=400)

            user.set_password(new_password)
            user.save()
            reset_otp.delete()

            return Response({'status': 'success', 'message': 'Password has been reset successfully'}, status=200)

        except PasswordResetOTP.DoesNotExist:
            return Response({'status': 'error', 'message': 'Invalid reset token'}, status=400)

    return Response(serializer.errors, status=400)

     
    
@api_view(['POST'])
def register_user(request):
    serializer = NewUserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response({"message": "User registered successfully", "status": "success"}, status=status.HTTP_201_CREATED)
    
    # Custom email error
    if "email_address" in serializer.errors:
        return Response({"message": "Email already exists", "status": "error"}, status=status.HTTP_400_BAD_REQUEST)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# User Login
class LoginView(APIView):
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data
            refresh = RefreshToken.for_user(user)
            
            # Get user profile data
            profile_data = {
                'user_id': user.user_id,
                'email_address': user.email_address,
                'full_name': user.full_name if hasattr(user, 'full_name') else '',
                'phone_number': user.phone_number if hasattr(user, 'phone_number') else '',
                'address': user.address if hasattr(user, 'address') else '',
                'shop_name': user.shop_name if hasattr(user, 'shop_name') else '',
                'user_type': user.user_type,  # Make sure this field exists in your User model
                'gender': user.gender if hasattr(user, 'gender') else '',
                'date_of_birth': user.date_of_birth.isoformat() if hasattr(user, 'date_of_birth') and user.date_of_birth else '',
                'profile_complete': True if all([user.full_name, user.phone_number, user.address]) else False,
            }
            
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                **profile_data
            })
        return Response(serializer.errors, status=400)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    user = request.user
    serializer = CustomUserSerializer(user)
    return Response(serializer.data)


@api_view(['POST'])
def create_tailor_shop(request):
    serializer = TailorShopSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)
    return Response(serializer.errors, status=400)


@api_view(['GET'])
def get_vendor_shop(request):
    try:
        shop = VendorShop.objects.first()  # Fetch the first shop for now
        if shop:
            serializer = VendorShopSerializer(shop)
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response({"message": "No shop found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def save_vendor_shop(request):
    serializer = VendorShopSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



class PasswordResetOTPView ( APIView ) :
    def post ( self , request ) :
        email = request.data.get ( 'email' )
        if not User.objects.filter ( email=email ).exists () :
            return Response ( {"error" : "User with this email does not exist"} , status=status.HTTP_404_NOT_FOUND )

        otp = random.randint ( 100000 , 999999 )  # Generate OTP
        send_mail (
            'Password Reset OTP' ,
            f'Your OTP for password reset is {otp}' ,
            'your-email@gmail.com' ,  # Replace with your Gmail
            [ email ] ,
            fail_silently=False ,
        )

        request.session [ 'reset_otp' ] = otp  # Store OTP in session
        return Response ( {"message" : "OTP sent successfully"} , status=status.HTTP_200_OK )


# Verify OTP & Reset Password
class VerifyOTPView ( APIView ) :
    def post ( self , request ) :
        otp = request.data.get ( 'otp' )
        new_password = request.data.get ( 'new_password' )

        if str ( request.session.get ( 'reset_otp' ) ) == str ( otp ) :
            user = User.objects.get ( email=request.data.get ( 'email' ) )
            user.set_password ( new_password )
            user.save ()
            return Response ( {"message" : "Password reset successful"} , status=status.HTTP_200_OK )

        return Response ( {"error" : "Invalid OTP"} , status=status.HTTP_400_BAD_REQUEST )


class OrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]  # Require authentication

    def get_queryset(self):
        return Order.objects.all()

    def list(self, request, *args, **kwargs):
        user = self.request.user
        view_type = self.request.query_params.get('view', 'available')

        queryset = self.get_queryset()

        if user.user_type == "Tailor":
            if view_type == "available":
                queryset = queryset.filter(is_accepted="Pending", tailor__isnull=True)
            elif view_type == "accepted":
                queryset = queryset.filter(tailor=user, is_accepted="Accepted")
            else:
                queryset = Order.objects.none()
        else:
            queryset = Order.objects.none()

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    
    @action(detail=True, methods=['PATCH'])
    def update_status(self, request, pk=None):
        order = self.get_object()
        order.status = request.data.get("status", order.status)
        order.save()
        return Response({"message": "Status updated successfully!"})
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendor_orders(request):
    user = request.user

    if user.user_type != "Vendor":
        return Response({"detail": "Not authorized"}, status=403)

    orders = Order.objects.filter(vendor=user)
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)    


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    serializer = OrderSerializer(data=request.data)

    if serializer.is_valid():
        order = serializer.save(vendor=request.user, customer=request.user)  # set manually
        return Response({"message": "Order created successfully!", "order": OrderSerializer(order).data}, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Orders API
class OrderListCreateView ( generics.ListCreateAPIView ) :
    queryset = Order.objects.all ()
    serializer_class = OrderSerializer
    permission_classes = [ IsAuthenticated ]


class OrderDetailView ( generics.RetrieveUpdateDestroyAPIView ) :
    queryset = Order.objects.all ()
    serializer_class = OrderSerializer
    permission_classes = [ IsAuthenticated ]


class OrderCustomizationListCreateView(generics.ListCreateAPIView):
    queryset = OrderCustomization.objects.all()
    serializer_class = OrderCustomizationSerializer2


class OrderCustomizationDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = OrderCustomization.objects.all()
    serializer_class = OrderCustomizationSerializer2


class MeasurementViewSet(viewsets.ModelViewSet):
    queryset = Measurement.objects.all()
    serializer_class = MeasurementSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Measurement.objects.filter(order__tailor=user, order__is_accepted='Accepted')
    
class AcceptedOrdersByTailor(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        orders = Order.objects.filter(tailor=user, is_accepted='Accepted')
        serializer = OrderDropdownSerializer(orders, many=True)
        return Response(serializer.data)    
    

def perform_create(self, serializer):
    user = self.request.user
    order = serializer.validated_data.get('order')

    # ensure tailor is the owner and order is accepted
    if order.tailor != user or order.is_accepted != 'Accepted':
        raise serializers.ValidationError("You can only add measurements to accepted orders assigned to you.")

    serializer.save()

def perform_update(self, serializer):
    user = self.request.user
    order = serializer.validated_data.get('order', serializer.instance.order)

    if order.tailor != user or order.is_accepted != 'Accepted':
        raise serializers.ValidationError("You can only update measurements for your accepted orders.")

    serializer.save()    


class MeasurementListCreateView(generics.ListCreateAPIView):
    serializer_class = MeasurementSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Measurement.objects.filter(customer=self.request.user)

    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)


class MeasurementRetrieveUpdateDeleteView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Measurement.objects.all()
    serializer_class = MeasurementSerializer
    permission_classes = [IsAuthenticated]


def admin_login(request):
    if request.method == "POST":
        email = request.POST.get("email_address")  # Get email from form
        password = request.POST.get("password")  # Get password from form

        try:
            user = NewUser.objects.get(email_address=email)  # Check if user exists
        except NewUser.DoesNotExist:
            user = None

        if user:
            user = authenticate(request, username=email, password=password)  # Authenticate with email

            if user is not None:
                login(request, user)
                return redirect("dashboard")  # Redirect to your dashboard
            else:
                messages.error(request, "Incorrect password")
        else:
            messages.error(request, "User with this email does not exist")

    return render(request, "login.html")


def admin_dashboard(request):
    return render(request, "dashboard.html")


def user_list(request):
    if request.method == "POST":
        full_name = request.POST.get("full_name")
        email_address = request.POST.get("email_address")
        phone_number = request.POST.get("phone_number")
        date_of_birth = request.POST.get("date_of_birth")
        gender = request.POST.get("gender")
        shop_name = request.POST.get("shop_name")
        user_type = request.POST.get("user_type")
        address = request.POST.get("address")
        password = request.POST.get("password")

        # Check if email already exists
        if NewUser.objects.filter(email_address=email_address).exists():
            messages.error(request, "Email already exists. Try another one.")
            return redirect("user_list")

        # Create a new user
        user = NewUser.objects.create(
            full_name=full_name,
            email_address=email_address,
            phone_number=phone_number,
            date_of_birth=date_of_birth,
            gender=gender,
            shop_name=shop_name,
            user_type=user_type,
            address=address
        )
        user.set_password(password)  # Hash the password
        user.save()

        messages.success(request, "Registration successful! You can now log in.")
        return redirect("dashboard")  # Redirect to login page
    return render(request, "user.html")


def measurement(request):
    if request.method == "POST":
        chest = request.POST.get("chest")
        waist = request.POST.get("waist")
        inseam = request.POST.get("inseam")
        shoulders = request.POST.get("shoulders")
        sleeve_length = request.POST.get("sleeve_length")


        # Create the measurement record
        measurement = Measurement.objects.create(
            customer=request.user,
            chest=chest,
            waist=waist,
            inseam=inseam,
            shoulders=shoulders,
            sleeve_length=sleeve_length
        )
        
        messages.success(request, "Measurement added successfully!")
        return redirect("measurement")  # Redirect to a measurement list pag
    return render(request, "measurement.html")


def order_customise(request):
    obj = Order.objects.all()
    if request.method == "POST":
        order_id = request.POST.get("order_id")
        fabric_choice = request.POST.get("fabric_choice")
        style_preferences = request.POST.get("style_preferences")
        color_options = request.POST.get("color_options")
        additional_details = request.POST.get("additional_details")

        # Validate order existence
        order = get_object_or_404(Order, id=order_id)

        # Create the order customization record
        OrderCustomization.objects.create(
            order=order,
            fabric_choice=fabric_choice,
            style_preferences=style_preferences,
            color_options=color_options,
            additional_details=additional_details
        )

        messages.success(request, "Customization added successfully!")
        return redirect("order_customise")  # Redirect to the customization list page
    return render(request, "order_customise.html", context={"obj":obj})


def orders(request):
    if request.method == "POST":
        customer_name = request.POST.get("customer_name")
        contact_number = request.POST.get("contact_number")
        clothing_types = request.POST.getlist("clothing_types[]")
        additional_instructions = request.POST.get("additional_instructions")
        price = request.POST.get("price")
        status = request.POST.get("status")
        order_photo = request.FILES["order_photo"]

        customer=request.user

        clothing_types_str = ", ".join(clothing_types)

        en = Order(
            customer=customer,
            customer_name=customer_name,
            contact_number=contact_number,
            clothing_types=clothing_types_str,
            additional_instructions=additional_instructions,
            price=price,
            status=status,
            order_photo=order_photo
        )
        en.save()
    return render(request, "orders.html")


def tailor(request):
    if request.method == "POST":
        shop_name = request.POST.get("shop_name")
        address = request.POST.get("address")
        latitude = request.POST.get("latitude")
        longitude = request.POST.get("longitude")
        business_hours = request.POST.get("business_hours")
        shop_photo = request.FILES.get("shop_photo")  # Handle image file upload

        # Create the tailor shop record
        TailorShop.objects.create(
            shop_name=shop_name,
            address=address,
            latitude=latitude,
            longitude=longitude,
            business_hours=business_hours,
            shop_photo=shop_photo
        )

        messages.success(request, "Tailor shop added successfully!")
        return redirect("tailor")  # Redirect to the shop list page
    return render(request, "tailor_profile.html")



def vendor(request):
    if request.method == "POST":
        shop_name = request.POST.get("shop_name")
        address = request.POST.get("address")
        latitude = request.POST.get("latitude")
        longitude = request.POST.get("longitude")
        business_hours = request.POST.get("business_hours")
        shop_photo = request.FILES.get("shop_photo")  # Handle image file upload

        # Create the vendor shop record
        VendorShop.objects.create(
            shop_name=shop_name,
            address=address,
            latitude=latitude,
            longitude=longitude,
            business_hours=business_hours,
            shop_photo=shop_photo
        )

        messages.success(request, "Vendor shop added successfully!")
        return redirect("vendor")
    return render(request, "vendor_profile.html")



def show_user(request):
    users= NewUser.objects.all()
    return render(request, "show_users.html", context={"users": users})


def edit_user(request, user_id):
    user = get_object_or_404(NewUser, user_id=user_id)

    if request.method == "POST":
        user.full_name = request.POST.get("full_name")
        user.email_address = request.POST.get("email_address")
        user.phone_number = request.POST.get("phone_number")
        user.date_of_birth = request.POST.get("date_of_birth")
        user.gender = request.POST.get("gender")
        user.shop_name = request.POST.get("shop_name")
        user.user_type = request.POST.get("user_type")
        user.save()
        return redirect("show_user")  # Redirect to the user list page

    return render(request, "edit_user.html", {"user": user})


def delete_user(request, user_id):
    user = get_object_or_404(NewUser, user_id=user_id)
    user.delete()
    return redirect("show_user")  # Redirect back to user list after deletion


def show_orders(request):
    orders = Order.objects.all()
    return render(request, "show_order.html", {"orders": orders})


def edit_order(request, order_id):
    order = get_object_or_404(Order, id=order_id)

    if request.method == "POST":
        order.customer_name = request.POST.get("customer_name")
        order.contact_number = request.POST.get("contact_number")
        order.clothing_types = request.POST.get("clothing_types[]")
        order.price = request.POST.get("price")
        order.status = request.POST.get("status")
        order.additional_instructions = request.POST.get("additional_instructions")
        order.save()
        return redirect("show_orders")  # Redirect to orders list

    return render(request, "edit_order.html", {"order": order})


def delete_order(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    order.delete()
    return redirect("show_orders")  # Redirect after deleting order



def show_measurement(request):
    measurements = Measurement.objects.all()
    print(measurements)  # This should show a queryset in the console.
    return render(request, "show_measurement.html", {"measurements": measurements})


def edit_measurement(request, measurement_id):
    measurement = get_object_or_404(Measurement, id=measurement_id)

    if request.method == "POST":
        measurement.chest = request.POST.get("chest")
        measurement.waist = request.POST.get("waist")
        measurement.inseam = request.POST.get("inseam")
        measurement.shoulders = request.POST.get("shoulders")
        measurement.sleeve_length = request.POST.get("sleeve_length")
        measurement.save()
        return redirect("show_measurements")  # Redirect to measurements list

    return render(request, "edit_measurement.html", {"measurement": measurement})


def delete_measurement(request, measurement_id):
    measurement = get_object_or_404(Measurement, id=measurement_id)
    measurement.delete()
    return redirect("show_measurements")  # Redirect after deleting measurement




def show_tailor_shops(request):
    shops = NewUser.objects.filter(user_type="Tailor")
    return render(request, "show_tailor_shops.html", {"shops": shops})



def edit_tailor_shop(request, user_id):
    shop = get_object_or_404(NewUser, user_id=user_id)
    
    if request.method == "POST":
        # Get data from the POST request
        shop.shop_name = request.POST.get("shop_name")
        shop.address = request.POST.get("address")
        shop.location = request.POST.get("location")
        shop.business_hours = request.POST.get("business_hours")
        
        # Handling image upload
        if 'shop_photo' in request.FILES:
            shop.image = request.FILES['shop_photo']
        
        shop.save()  # Save the changes
        return redirect('show_tailor_shops')  # Redirect after saving

    return render(request, "edit_tailor_shop.html", {"shop": shop})



def delete_tailor_shop(request, user_id):
    shop = get_object_or_404(NewUser, user_id=user_id)
    shop.delete()  # Delete the shop
    return redirect('show_tailor_shops')  # Redirect after deletion


def show_vendor_shops(request):
    shops = NewUser.objects.filter(user_type="Vendor")  # Fetch all vendor shops from the database
    return render(request, "show_vendor_shops.html", {"shops": shops})


def edit_vendor_shop(request, user_id):
    shop = get_object_or_404(NewUser, user_id=user_id)
    
    if request.method == "POST":
        # Get data from the POST request
        shop.shop_name = request.POST.get("shop_name")
        shop.address = request.POST.get("address")
        shop.location = request.POST.get("location")
        shop.business_hours = request.POST.get("business_hours")
        
        # Handling image upload
        if 'shop_photo' in request.FILES:
            shop.image = request.FILES['shop_photo']
        
        shop.save()  # Save the changes
        return redirect('show_vendor_shops')  # Redirect after saving

    return render(request, "edit_vendor_shop.html", {"shop": shop})


def delete_vendor_shop(request, user_id):
    shop = get_object_or_404(NewUser, user_id=user_id)
    shop.delete()  # Delete the shop
    return redirect('show_vendor_shops')  # Redirect after deletion


def show_order_customizations(request):
    customizations = OrderCustomization.objects.all()  # Fetch all order customizations from the database
    return render(request, "show_order_customizations.html", {"customizations": customizations})



def edit_order_customization(request, customization_id):
    customization = get_object_or_404(OrderCustomization, id=customization_id)
    
    if request.method == "POST":
        # Get data from the POST request
        customization.fabric_choice = request.POST.get("fabric_choice")
        customization.style_preferences = request.POST.get("style_preferences")
        customization.color_options = request.POST.get("color_options")
        customization.additional_details = request.POST.get("additional_details")
        
        
        customization.save()  # Save the changes
        return redirect('show_order_customizations')  # Redirect after saving

    return render(request, "edit_order_customization.html", {"customization": customization})


def delete_order_customization(request, customization_id):
    customization = get_object_or_404(OrderCustomization, id=customization_id)
    customization.delete()  # Delete the customization
    return redirect('show_order_customizations')  # Redirect after deletion


def appointment(request):
    if request.method == "POST":
        date = request.POST.get("date")
        time_slot = request.POST.get("time_slot")
        name = request.POST.get("name")
        contact = request.POST.get("contact")
        remark = request.POST.get("remark")

        Appointment.objects.create(
            date=date,
            time_slot=time_slot,
            name=name,
            contact=contact,
            remark=remark
        )
        return redirect('show_appointments')
    return render(request, "appointment.html")


def show_appointments(request):
    appointments = Appointment.objects.all()
    return render(request, "show_appointments.html", {"appointments": appointments})


def edit_appointment(request, appointment_id):
    appointment = get_object_or_404(Appointment, id=appointment_id)

    if request.method == "POST":
        appointment.date = request.POST.get("date")
        appointment.time_slot = request.POST.get("time_slot")
        appointment.name = request.POST.get("name")
        appointment.contact = request.POST.get("contact")
        appointment.remark = request.POST.get("remark")
        
        appointment.save()  # Save the changes
        return redirect('show_appointments')  # Redirect to the list of appointments after saving

    return render(request, "edit_appointment.html", {"appointment": appointment})



def delete_appointment(request, appointment_id):
    appointment = get_object_or_404(Appointment, id=appointment_id)
    appointment.delete()  # Delete the appointment
    return redirect('show_appointments')  # Redirect after deletion


@csrf_exempt
@login_required
def create_appointment(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            date_str = data.get('date')
            date_obj = datetime.strptime(date_str, '%Y-%m-%d').date()
            
            appointment = Appointment.objects.create(
                user=request.user,  # Use logged-in user
                date=date_obj,
                time_slot=data.get('time_slot'),
                name=data.get('name'),
                contact=data.get('contact'),
                remark=data.get('purpose', '')
            )
            
            return JsonResponse({
                'success': True,
                'message': 'Appointment created successfully',
                'id': appointment.id
            })
        except Exception as e:
            return JsonResponse({'success': False, 'message': str(e)}, status=400)
    
    return JsonResponse({'success': False, 'message': 'Invalid request method'}, status=405)




@csrf_exempt
@login_required  # Only allows authenticated users
def appointment_list(request):
    """API endpoint to get appointments for the logged-in user"""
    if request.method == 'GET':
        user = request.user
        appointments = Appointment.objects.filter(user=user).order_by('-created_at')
        appointment_list = []

        for appointment in appointments:
            appointment_list.append({
                'id': appointment.id,
                'date': appointment.date.strftime('%Y-%m-%d'),
                'time_slot': appointment.time_slot,
                'name': appointment.name,
                'contact': appointment.contact,
                'remark': appointment.remark,
                'created_at': appointment.created_at.strftime('%Y-%m-%d %H:%M:%S')
            })

        return JsonResponse(appointment_list, safe=False)
    
    return JsonResponse({'error': 'Method not allowed'}, status=405)

@csrf_exempt
def appointment_detail(request, appointment_id):
    """API endpoint to get, update, or delete a specific appointment"""
    try:
        appointment = Appointment.objects.get(id=appointment_id)
    except Appointment.DoesNotExist:
        return JsonResponse({'error': 'Appointment not found'}, status=404)
    
    # GET - Return appointment details
    if request.method == 'GET':
        appointment_data = {
            'id': appointment.id,
            'date': appointment.date.strftime('%Y-%m-%d'),
            'time_slot': appointment.time_slot,
            'name': appointment.name,
            'contact': appointment.contact,
            'remark': appointment.remark,
            'created_at': appointment.created_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        return JsonResponse(appointment_data)
    
    # PUT - Update appointment
    elif request.method == 'PUT':
        try:
            data = json.loads(request.body)
            
            # Update fields
            if 'date' in data:
                appointment.date = datetime.strptime(data['date'], '%Y-%m-%d').date()
            if 'time_slot' in data:
                appointment.time_slot = data['time_slot']
            if 'name' in data:
                appointment.name = data['name']
            if 'contact' in data:
                appointment.contact = data['contact']
            if 'remark' in data:
                appointment.remark = data['remark']
            
            appointment.save()
            
            return JsonResponse({
                'success': True,
                'message': 'Appointment updated successfully'
            })
        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': str(e)
            }, status=400)
    
    # DELETE - Delete appointment
    elif request.method == 'DELETE':
        appointment.delete()
        return JsonResponse({}, status=204)  # No content
    
    return JsonResponse({'error': 'Method not allowed'}, status=405)


#class MeasurementViewSet(viewsets.ModelViewSet):
#    queryset = Measurement.objects.all()
 #   serializer_class = MeasurementSerializer
 #   permission_classes = [IsAuthenticatedOrReadOnly]


class UserListView(generics.ListAPIView):
    """
    API view to retrieve list of all users
    """
    queryset = NewUser.objects.all()
    serializer_class = NewUserSerializer
    permission_classes = [AllowAny]  # Allow anyone to view the list


@api_view(['GET'])
def get_user_by_email(request, email):
    try:
        user = NewUser.objects.get(email=email)
        serializer = NewUserSerializer(user)
        return Response(serializer.data)
    except NewUser.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)        
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    user = request.user
    shop_name = request.data.get('shop_name')
    image_file = request.FILES.get('image')  # For multipart
    image_base64 = request.data.get('image')  # For base64
    image_name = request.data.get('image_name', 'profile.jpg')

    if shop_name:
        user.shop_name = shop_name

    if image_file:
        user.image = image_file
    elif image_base64:
        format, imgstr = image_base64.split(';base64,') if ';base64,' in image_base64 else ('data:image/jpeg', image_base64)
        ext = format.split('/')[-1]
        user.image.save(f'{image_name}', ContentFile(base64.b64decode(imgstr)), save=False)

    user.save()
    return Response({"message": "Profile updated successfully"})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_order_decision(request, order_id):
    try:
        order = Order.objects.get(id=order_id)
    except Order.DoesNotExist:
        return Response({"error": "Order not found"}, status=404)

    decision = request.data.get("decision")
    if decision not in ["Accepted", "Declined"]:
        return Response({"error": "Invalid decision"}, status=400)

    order.is_accepted = decision
    if decision == "Accepted":
        order.tailor = request.user  # assuming request.user is a tailor
    order.save()

    return Response({"message": f"Order {decision.lower()} successfully."})
    

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customization_list(request):
    from django.db.models import Max

    # Get only orders accepted by the currently logged-in tailor
    user = request.user
    tailor_orders = Order.objects.filter(tailor=user)

    # Get latest customization IDs for those orders
    latest_ids = OrderCustomization.objects.filter(order__in=tailor_orders).values('order').annotate(
        latest_id=Max('id')
    ).values_list('latest_id', flat=True)

    # Retrieve latest customization objects
    latest_customizations = OrderCustomization.objects.filter(
        id__in=list(latest_ids)
    ).select_related('order')

    serializer = OrderCustomizationSerializer(latest_customizations, many=True)
    return Response(serializer.data)



@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_shop_details(request):
    """
    API endpoint to get shop details for the logged-in Tailor user
    """
    user = request.user
    
    # Check if user is a Tailor
    if user.user_type != 'Tailor':
        return Response({"error": "Only Tailor accounts can access shop details"}, 
                         status=status.HTTP_403_FORBIDDEN)
    
    # Return shop-related information
    data = {
        'shop_name': user.shop_name,
        'address': user.address,
        'location': user.location,
        'business_hours': user.business_hours,
        'image': request.build_absolute_uri(user.image.url) if user.image else None
    }
    
    return Response(data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_shop_details(request):
    """
    API endpoint to update shop details for the logged-in Tailor user
    """
    user = request.user
    
    # Check if user is a Tailor
    if user.user_type != 'Tailor':
        return Response({"error": "Only Tailor accounts can update shop details"}, 
                         status=status.HTTP_403_FORBIDDEN)
    
    # Update shop information
    if 'shop_name' in request.data:
        user.shop_name = request.data['shop_name']
    
    if 'address' in request.data:
        user.address = request.data['address']
    
    if 'location' in request.data:
        user.location = request.data['location']

    if 'business_hours' in request.data:
        user.business_hours = request.data['business_hours']    
    
    # Handle image upload based on request content-type
    if request.content_type == 'application/json' and 'image' in request.data:
        # Handle base64 encoded image (from web)
        format, imgstr = request.data['image'].split(';base64,') if ';base64,' in request.data['image'] else ('', request.data['image'])
        ext = request.data.get('image_name', '').split('.')[-1]
        if not ext:
            ext = 'jpg'
        
        data = ContentFile(base64.b64decode(imgstr), name=f'shop_image_{user.user_id}.{ext}')
        user.image = data
    
    # Handle multipart form data (from mobile)
    elif request.FILES and 'image' in request.FILES:
        user.image = request.FILES['image']
    
    user.save()
    
    return Response({"message": "Shop details updated successfully"})



@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_vendor_shop_details(request):
    """
    API endpoint to get shop details for the logged-in Vendor user
    """
    user = request.user
    
    # Check if user is a Vendor
    if user.user_type != 'Vendor':
        return Response({"error": "Only Vendor accounts can access shop details"}, 
                         status=status.HTTP_403_FORBIDDEN)
    
    # Return shop-related information
    data = {
        'shop_name': user.shop_name,
        'address': user.address,
        'location': user.location,
        'image': request.build_absolute_uri(user.image.url) if user.image else None,
        'business_hours': user.business_hours
    }
    
    return Response(data)



@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_vendor_shop_details(request):
    """
    API endpoint to update shop details for the logged-in Tailor user
    """
    user = request.user
    
    # Check if user is a Vendor
    if user.user_type != 'Vendor':
        return Response({"error": "Only Tailor accounts can update shop details"}, 
                         status=status.HTTP_403_FORBIDDEN)
    
    # Update shop information
    if 'shop_name' in request.data:
        user.shop_name = request.data['shop_name']
    
    if 'address' in request.data:
        user.address = request.data['address']
    
    if 'location' in request.data:
        user.location = request.data['location']

    if 'business_hours' in request.data:
        user.business_hours = request.data['business_hours']    
    
    # Handle image upload based on request content-type
    if request.content_type == 'application/json' and 'image' in request.data:
        # Handle base64 encoded image (from web)
        format, imgstr = request.data['image'].split(';base64,') if ';base64,' in request.data['image'] else ('', request.data['image'])
        ext = request.data.get('image_name', '').split('.')[-1]
        if not ext:
            ext = 'jpg'
        
        data = ContentFile(base64.b64decode(imgstr), name=f'shop_image_{user.user_id}.{ext}')
        user.image = data
    
    # Handle multipart form data (from mobile)
    elif request.FILES and 'image' in request.FILES:
        user.image = request.FILES['image']
    
    user.save()
    
    return Response({"message": "Shop details updated successfully"})



class AppointmentListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        print(f"User type: {user.user_type}")
        # Check if the user is a vendor
        if user.user_type == 'Vendor':
            print(f"Filtering appointments for vendor ID: {user.user_id}")
            # If vendor, show appointments where they are the selected vendor
            appointments = Appointment.objects.filter(vendor=user).order_by('-created_at')
            print(f"Found {appointments.count()} appointments")
        else:
            # If tailor or other user type, show their created appointments
            appointments = Appointment.objects.filter(user=user).order_by('-created_at')
            
        serializer = AppointmentSerializer(appointments, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = AppointmentSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response({
                'success': True,
                'message': 'Appointment created successfully',
                'appointment': serializer.data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AppointmentDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, pk, user):
        try:
            # Check if the user is the creator or the vendor
            appointment = Appointment.objects.filter(
                Q(pk=pk) & (Q(user=user) | Q(vendor=user))
            ).first()
            return appointment
        except Appointment.DoesNotExist:
            return None

    def get(self, request, pk):
        appointment = self.get_object(pk, request.user)
        if appointment is None:
            return Response({'error': 'Not found'}, status=404)
        serializer = AppointmentSerializer(appointment)
        return Response(serializer.data)

    def put(self, request, pk):
        appointment = self.get_object(pk, request.user)
        if appointment is None:
            return Response({'error': 'Not found'}, status=404)

        serializer = AppointmentSerializer(appointment, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({'success': True, 'message': 'Appointment updated successfully'})
        return Response(serializer.errors, status=400)

    def delete(self, request, pk):
        appointment = self.get_object(pk, request.user)
        if appointment is None:
            return Response({'error': 'Not found'}, status=404)
        appointment.delete()
        return Response(status=204)    
    

class VendorListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        vendors = NewUser.objects.filter(user_type='Vendor')
        serializer = VendorSerializer(vendors, many=True)
        return Response(serializer.data)    
    

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tailor_orders(request):
    user = request.user
    orders = Order.objects.filter(tailor=user)
    serializer = OrderSerializer(orders, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendor_orders(request):
    vendor = request.user
    orders = Order.objects.filter(vendor=vendor).order_by('-created_at')
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)