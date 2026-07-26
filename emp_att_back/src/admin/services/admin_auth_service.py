# src/admin/services/admin_auth_service.py
from firebase_admin import auth
from src.services.firebase_service import db  
from functools import wraps
from flask import request, jsonify

def verify_admin_login(id_token):
    try:
        # 1. Verify the token using your existing Firebase Admin SDK
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        # 2. Check if this authenticated user is actually in the 'admins' collection
        admin_ref = db.collection('admins').document(uid).get()
        
        if not admin_ref.exists:
            raise Exception("Access denied. User is not an administrator.")
            
        # 3. Return the admin data
        return admin_ref.to_dict()
        
    except Exception as e:
        raise Exception(f"Authentication failed: {str(e)}")

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"status": "error", "message": "Missing or invalid Authorization header"}), 401
            
        id_token = auth_header.split('Bearer ')[1]
        try:
            # Reusing the existing function to check admin rights
            verify_admin_login(id_token)
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 403
            
        return f(*args, **kwargs)
    return decorated_function