from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import User
from rest_framework_simplejwt.tokens import RefreshToken

class SendOTP(APIView):
    def post(self, request):
        phone = request.data.get('phone_number')
        # Here you would call an SMS API (Twilio/Firebase)
        # For now, we just pretend it's sent
        return Response({"message": "OTP sent to " + phone}, status=status.HTTP_200_OK)

class VerifyOTP(APIView):
    def post(self, request):
        phone = request.data.get('phone_number')
        name = request.data.get('full_name') 
        otp = request.data.get('otp')
        is_owner = request.data.get('is_shop_owner', False)
        
        # Hardcoded for development; replace with actual validation logic later
        if otp == "1234":
            user, created = User.objects.get_or_create(
                phone_number=phone,
                defaults={
                    'full_name': name,
                    'is_shop_owner': is_owner,
                    'is_customer': not is_owner,
                }
            )
            
            # If the user existed but the name was updated in Flutter, 
            # you might want to update it here (optional)
            if not created and name:
                user.full_name = name
                user.save()

            refresh = RefreshToken.for_user(user)
            
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'full_name': user.full_name,
                'phone_number': user.phone_number,
                # Explicit role string for Flutter logic
                'role': 'shop_owner' if user.is_shop_owner else 'customer',
                'shop_approved': user.shop.is_active if user.is_shop_owner and hasattr(user, 'shop') else False,
                'shop_name': user.shop.shop_name if user.is_shop_owner and hasattr(user, 'shop') else '',
                'is_shop_owner': user.is_shop_owner,
                'is_new_user': created
            }, status=status.HTTP_200_OK)
            
        return Response({"error": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)