from flask import Blueprint, request, jsonify
from src.services.firebase_service import verify_token_and_get_uid
from src.services.attendance_service import mark_check_in, mark_check_out, get_user_attendance_history, get_today_status

attendance_bp = Blueprint('attendance', __name__)

@attendance_bp.route('/check-in', methods=['POST'])
def check_in():
    data = request.json or {}
    token = data.get('id_token')
    lat = data.get('latitude')
    lng = data.get('longitude')

    if not all([token, lat, lng]):
        return jsonify({"error": "Missing token or coordinates"}), 400

    uid = verify_token_and_get_uid(token)
    if not uid:
        return jsonify({"error": "Invalid token"}), 401

    result = mark_check_in(uid, lat, lng)
    
    if "error" in result:
        return jsonify(result), 400
    return jsonify(result), 200

@attendance_bp.route('/check-out', methods=['POST'])
def check_out():
    data = request.json or {}
    token = data.get('id_token')
    lat = data.get('latitude')
    lng = data.get('longitude')

    if not all([token, lat, lng]):
        return jsonify({"error": "Missing token or coordinates"}), 400

    uid = verify_token_and_get_uid(token)
    if not uid:
        return jsonify({"error": "Invalid token"}), 401

    result = mark_check_out(uid, lat, lng)
    
    if "error" in result:
        return jsonify(result), 400
    return jsonify(result), 200

@attendance_bp.route('/history', methods=['POST'])
def history():
    data = request.json or {}
    token = data.get('id_token')

    uid = verify_token_and_get_uid(token)
    if not uid:
        return jsonify({"error": "Invalid token"}), 401

    # No longer passing 'month'
    result = get_user_attendance_history(uid)
    
    if "error" in result:
        return jsonify(result), 400
        
    return jsonify({"data": result}), 200

@attendance_bp.route('/today-status', methods=['POST'])
def get_today_status_route():
    data = request.json or {}
    token = data.get('id_token')
    
    uid = verify_token_and_get_uid(token)
    if not uid:
        return jsonify({"error": "Invalid token"}), 401

    status = get_today_status(uid)
    return jsonify({"data": status}), 200