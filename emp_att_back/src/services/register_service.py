import datetime
import cloudinary.uploader
from src.services.firebase_service import db
import os
from dotenv import load_dotenv

# Load variables from the .env file
load_dotenv()

# Configure Cloudinary with your credentials
# Note: For production, it is highly recommended to move these to a .env file!
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET")
)

def create_registration_request(full_name, email, phone, image_file):
    try:
        profile_image_url = ""
        
        # 1. Upload to Cloudinary if an image was provided
        if image_file:
            upload_result = cloudinary.uploader.upload(
                image_file,
                folder="registration_avatars"
            )
            profile_image_url = upload_result.get('secure_url', "")

        # 2. Build the exact schema you requested
        request_data = {
            "full_name": full_name,
            "email": email,
            "phone": phone,
            "office_id": "", # Empty per requirements
            "profile_image_url": profile_image_url,
            "status": "Pending",
            "requested_at": datetime.datetime.now(datetime.timezone.utc),
            "admin_notes": "" # Empty per requirements
        }

        # 3. Save to Firestore (this creates the collection automatically)
        db.collection("registration_requests").add(request_data)
        
        return {"success": True, "message": "Registration submitted for admin approval."}

    except Exception as e:
        print(f"Error in register_service: {e}")
        return {"success": False, "error": str(e)}