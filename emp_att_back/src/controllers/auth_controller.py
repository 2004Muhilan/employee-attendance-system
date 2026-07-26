from flask import Blueprint, request, jsonify
from src.services.firebase_service import verify_token_and_get_uid, get_employee_profile
from src.services.register_service import create_registration_request

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        # 1. Get Data from Request
        data = request.json
        if not data or 'id_token' not in data:
            return jsonify({"error": "Missing 'id_token' in request body"}), 400
            
        id_token = data['id_token']

        # 2. Verify who this user is
        uid = verify_token_and_get_uid(id_token)
        if not uid:
            return jsonify({"error": "Invalid or expired token"}), 401

        # 3. Get their profile from Firestore
        user_profile = get_employee_profile(uid)

        if not user_profile:
            return jsonify({"error": "User profile not found. Please contact HR."}), 404
            
        # 4. Check if account is active (Consultancy Best Practice)
        if not user_profile.get('is_active', False):
             return jsonify({"error": "Account is disabled."}), 403

        # 5. Return success
        return jsonify({
            "status": "success",
            "message": "Login successful",
            "data": user_profile
        }), 200

    except Exception as e:
        return jsonify({"error": f"Internal Server Error: {str(e)}"}), 500

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        # 1. Get Data from Multipart Request
        full_name = request.form.get('full_name')
        email = request.form.get('email')
        phone = request.form.get('phone')
        
        # 'profile_image' matches the key we will send from Flutter
        image_file = request.files.get('profile_image') 

        # 2. Basic Validation
        if not full_name or not email or not phone:
            return jsonify({"error": "Missing required fields (name, email, phone)."}), 400

        # 3. Pass to Service
        result = create_registration_request(full_name, email, phone, image_file)

        # 4. Return Response
        if result.get("success"):
            return jsonify({"status": "success", "message": result["message"]}), 201
        else:
            return jsonify({"error": result.get("error")}), 500

    except Exception as e:
        return jsonify({"error": f"Internal Server Error: {str(e)}"}), 500