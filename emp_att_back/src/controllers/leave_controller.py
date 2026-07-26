from flask import Blueprint, request, jsonify
from src.services.leave_service import create_leave_request_in_db, get_employee_leave_requests
from src.services.firebase_service import verify_token_and_get_uid, get_employee_profile

leave_bp = Blueprint('leave_bp', __name__)

@leave_bp.route('/submit', methods=['POST'])
def submit_leave():
    data = request.get_json() or {}
    
    id_token = data.get('id_token')
    if not id_token:
        return jsonify({"success": False, "message": "Missing id_token"}), 400
        
    uid = verify_token_and_get_uid(id_token)
    if not uid:
        return jsonify({"success": False, "message": "Invalid token"}), 401
        
    user_profile = get_employee_profile(uid)
    if not user_profile:
        return jsonify({"success": False, "message": "User profile not found"}), 404
        
    # Override eid with actual user's eid
    data['eid'] = user_profile.get('employee_id')
    
    # Basic validation
    required_fields = ['eid', 'leave_type', 'start_date', 'end_date', 'reason', 'total_days']
    if not all(field in data for field in required_fields):
        return jsonify({"success": False, "message": "Missing required fields"}), 400
        
    result = create_leave_request_in_db(data)
    
    if result["success"]:
        return jsonify(result), 201
    else:
        return jsonify(result), 500

@leave_bp.route('/history', methods=['POST'])
def get_leave_history():
    data = request.get_json() or {}
    id_token = data.get('id_token')
    if not id_token:
        return jsonify({"success": False, "message": "Missing id_token"}), 400
        
    uid = verify_token_and_get_uid(id_token)
    if not uid:
        return jsonify({"success": False, "message": "Invalid token"}), 401
        
    user_profile = get_employee_profile(uid)
    if not user_profile:
        return jsonify({"success": False, "message": "User profile not found"}), 404
        
    eid = user_profile.get('employee_id')
    result = get_employee_leave_requests(eid)
    
    if result["success"]:
        return jsonify(result), 200
    else:
        return jsonify(result), 500