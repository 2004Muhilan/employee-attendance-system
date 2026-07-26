from src.services.firebase_service import db
import firebase_admin.auth as auth
from datetime import datetime, timezone
import random

def get_all_registration_requests():
    try:
        # Fetch all registration requests, ordering by newest first
        docs = db.collection('registration_requests').order_by('requested_at', direction='DESCENDING').stream()
        
        requests_list = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            
            # Firestore returns datetime objects, which JSON can't natively serialize.
            # We convert it to an ISO string for the React frontend.
            if 'requested_at' in data and data['requested_at']:
                data['requested_at'] = data['requested_at'].isoformat()
                
            requests_list.append(data)
            
        return requests_list
        
    except Exception as e:
        raise Exception(f"Failed to fetch registration requests: {str(e)}")

def update_registration_status(request_id, status, office_id, role, admin_notes):
    try:
        doc_ref = db.collection('registration_requests').document(request_id)
        doc = doc_ref.get()
        if not doc.exists:
            raise Exception("Registration request not found")
            
        request_data = doc.to_dict()
            
        update_data = {
            "status": status,
            "office_id": office_id,
            "role": role,
            "admin_notes": admin_notes
        }
        
        if status == "Approved" and request_data.get("status") != "Approved":
            email = request_data.get('email')
            full_name = request_data.get('full_name')
            phone = request_data.get('phone')
            
            # Default password for new employees
            password = "Password@123"
            
            # Create user in Firebase Auth
            # Omit phone if it's not strictly formatted with E.164 (+) to avoid Firebase errors
            auth_kwargs = {
                "email": email,
                "password": password,
                "display_name": full_name
            }
            if phone and phone.startswith('+'):
                auth_kwargs["phone_number"] = phone
                
            user = auth.create_user(**auth_kwargs)
            
            # Generate a simple employee_id
            employee_id = f"EMP{random.randint(1000, 9999)}"
            
            # Create employee document
            emp_data = {
                "employee_id": employee_id,
                "email": email,
                "full_name": full_name,
                "phone": phone,
                "office_id": office_id,
                "role": role,
                "is_active": True,
                "profile_image_url": request_data.get('profile_image_url', ''),
                "created_at": datetime.now(timezone.utc)
            }
            
            db.collection('employees').document(user.uid).set(emp_data)
        
        doc_ref.update(update_data)
        return update_data
        
    except Exception as e:
        raise Exception(f"Failed to update request: {str(e)}")