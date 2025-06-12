from django.urls import path, include
from .views import *
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView


router = DefaultRouter()
router.register(r'orders', OrderViewSet, basename='order')
router.register(r'measurements', MeasurementViewSet, basename='measurement')

urlpatterns = [


    # Authentication APIs
    path('register/', register_user, name='register_user'),
    path('login/', LoginView.as_view(), name='login_user'),
    path('reset-password/', PasswordResetOTPView.as_view(), name='reset-password'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),


    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),  # Login
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),  # Refresh expired token


    path('', include(router.urls)),
    path('create-order/', create_order, name='create_order'),

    # Measurement APIs
    path ( 'measurements/' , MeasurementListCreateView.as_view () , name="measurements-list-create" ) ,
    path ( 'measurements/<int:pk>/' , MeasurementRetrieveUpdateDeleteView.as_view () , name="measurement-detail" ) ,
    path('add-shop/', create_tailor_shop, name='add-shop'),
    path('vendor-shop/', get_vendor_shop, name='get_vendor_shop'),
    path('vendor-shop/save/', save_vendor_shop, name='save_vendor_shop'),
    path('customizations/', OrderCustomizationListCreateView.as_view(), name='customization-list-create'),
    path('customizations/<int:pk>/', OrderCustomizationDetailView.as_view(), name='customization-detail'),



    path('admin_login/', admin_login, name="admin_login"),
    path('dashboard/', admin_dashboard, name="dashboard"),
    path('users/', user_list, name="user_list"),
    path('measurement/', measurement, name="measurement"),
    path('order_customise/', order_customise, name="order_customise"),
    path('user_orders/', orders, name="user_orders"),
    path('tailors/', tailor, name="tailor"),
    path('vendors/', vendor, name="vendor"),


    path('show_users/', show_user, name="show_user"),
    path("edit_user/<int:user_id>/", edit_user, name="edit_user"),
    path("delete_user/<int:user_id>/", delete_user, name="delete_user"),


    path('show_orders/', show_orders, name="show_orders"),
    path("edit_order/<int:order_id>/", edit_order, name="edit_order"),
    path("delete_order/<int:order_id>/", delete_order, name="delete_order"),


    path("show_measurements/", show_measurement, name="show_measurements"),
    path("edit_measurement/<int:measurement_id>/", edit_measurement, name="edit_measurement"),
    path("delete_measurement/<int:measurement_id>/", delete_measurement, name="delete_measurement"),


    path('show_tailor_shops/', show_tailor_shops, name='show_tailor_shops'),
    path('edit_shop/<int:user_id>/', edit_tailor_shop, name='edit_tailor_shop'),
    path('delete_shop/<int:user_id>/', delete_tailor_shop, name='delete_tailor_shop'),


    path('show_vendor_shops/', show_vendor_shops, name='show_vendor_shops'),
    path('edit_vendor_shop/<int:user_id>/', edit_vendor_shop, name='edit_vendor_shop'),
    path('delete_vendor_shop/<int:user_id>/', delete_vendor_shop, name='delete_vendor_shop'),


    path('show_order_customizations/', show_order_customizations, name='show_order_customizations'),
    path('edit_order_customization/<int:customization_id>/', edit_order_customization, name='edit_order_customization'),
    path('delete_order_customization/<int:customization_id>/', delete_order_customization, name='delete_order_customization'),


    path('appointment/', appointment, name="appointment"),
    path('show_appointments/', show_appointments, name='show_appointments'),
    path('edit_appointment/<int:appointment_id>/', edit_appointment, name='edit_appointment'),
    path('delete_appointment/<int:appointment_id>/', delete_appointment, name='delete_appointment'),

    #path('appointments/create/', create_appointment, name='create_appointment'),
    #path('appointments/', appointment_list, name='appointment_list'),
    #path('appointments/<int:appointment_id>/', appointment_detail, name='appointment_detail'),

    path('appointments/', AppointmentListCreateView.as_view(), name='appointment-list-create'),
    path('appointments/<int:pk>/', AppointmentDetailView.as_view(), name='appointment-detail'),
    path('vendor/', VendorListView.as_view(), name='vendor-list'),


    path('password-reset/request/', request_password_reset, name='request_password_reset'),
    path('password-reset/verify-otp/', verify_otp, name='verify_otp'),
    path('password-reset/set-new-password/', set_new_password, name='set_new_password'),


    path('get-csrf-token/', get_csrf_token, name='get_csrf_token'),

    path('new-users/', UserListView.as_view(), name='user-list'),
    path('api/new-users/email/<str:email>/', get_user_by_email),
    path('update-profile/', update_profile, name='update_profile'),


    path('orders/<int:order_id>/decision/', update_order_decision),
    path('customizationsv/', customization_list, name='customization-list'),

    path('shop-details/', get_shop_details, name='shop-details'),
    path('update-shop/', update_shop_details, name='update-shop'),



    path('vendor-shop-details/', get_vendor_shop_details, name='vendor-shop-details'),
    path('update-vendor-shop/', update_vendor_shop_details, name='update-vendor-shop'),


    path('profile/', get_user_profile),


    path('vendor/orders/', vendor_orders, name='vendor-orders'),
    path('accepted-orders/', AcceptedOrdersByTailor.as_view(), name='accepted-orders'),


    path('tailor-orders/', tailor_orders),
    path('vendor-orders/', vendor_orders, name='vendor-orders'),
    

    

]
