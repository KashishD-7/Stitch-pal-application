from django.contrib import admin
from .models import *
from django.utils.html import mark_safe

class NewUserAdmin(admin.ModelAdmin):
    list_display = ('email_address','user_type', 'full_name','phone_number', 'image_preview')
    readonly_fields = ('image_preview',)

    def image_preview(self, obj):
        if obj.image:
            return mark_safe(f'<img src="{obj.image.url}" width="100" height="100" style="object-fit: cover;" />')
        return "No image"
    image_preview.short_description = 'Image Preview'

admin.site.register(NewUser, NewUserAdmin)
admin.site.register(TailorShop)
admin.site.register(Order)
admin.site.register(OrderCustomization)
admin.site.register(Measurement)
admin.site.register(VendorShop)
admin.site.register(Appointment)
