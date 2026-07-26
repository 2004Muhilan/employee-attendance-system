from flask import Blueprint, request, jsonify
from src.services.firebase_service import verify_token_and_get_uid, get_employee_profile
from src.services.geofence_service import get_office_details

geofence_bp = Blueprint('geofence', __name__)

@geofence_bp.route('/my-office', methods=['POST'])
def get_my_office_geofence():
    try:
        # 1. Verify User
        data = request.json
        if not data or 'id_token' not in data:
            return jsonify({"error": "Missing 'id_token'"}), 400
            
        uid = verify_token_and_get_uid(data['id_token'])
        if not uid:
            return jsonify({"error": "Invalid or expired token"}), 401

        # 2. Get Employee Profile to find their Office ID
        user_profile = get_employee_profile(uid)
        if not user_profile:
            return jsonify({"error": "User profile not found"}), 404

        office_id = user_profile.get('office_id')
        if not office_id:
            return jsonify({"error": "No office assigned to this employee. Contact HR."}), 400

        # 3. Get Office Geofence Data
        office_data = get_office_details(office_id)
        
        if "error" in office_data:
            return jsonify(office_data), 404

        return jsonify({
            "status": "success",
            "data": office_data
        }), 200

    except Exception as e:
        return jsonify({"error": f"Server Error: {str(e)}"}), 500