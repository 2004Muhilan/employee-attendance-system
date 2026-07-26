from flask import Blueprint, request, jsonify
from src.admin.services.admin_auth_service import verify_admin_login 

admin_auth_bp = Blueprint('admin_auth', __name__)

@admin_auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    id_token = data.get('id_token') # <--- Now we only ask for the token

    if not id_token:
        return jsonify({"status": "error", "message": "ID token is required"}), 400

    try:
        admin_data = verify_admin_login(id_token) 
        
        return jsonify({
            "status": "success",
            "message": "Admin verified successfully",
            "data": {
                "admin_data": admin_data
                # We don't need to return the token, React already has it!
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 401