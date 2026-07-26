from flask import Blueprint, jsonify, request
from src.admin.services.admin_registration_service import get_all_registration_requests, update_registration_status
from src.admin.services.admin_auth_service import admin_required

# We don't define the prefix here so we can manage it cleanly in app.py
admin_registration_bp = Blueprint('admin_registration', __name__)

@admin_registration_bp.route('/registration-requests', methods=['GET'])
@admin_required
def get_registration_requests():
    try:
        requests_data = get_all_registration_requests()
        
        return jsonify({
            "status": "success",
            "data": requests_data
        }), 200
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@admin_registration_bp.route('/registration-requests/<request_id>', methods=['PUT'])
@admin_required
def update_registration_request(request_id):
    data = request.get_json()
    status = data.get('status')
    office_id = data.get('office_id')
    role = data.get('role')
    admin_notes = data.get('admin_notes')
    
    try:
        updated_data = update_registration_status(request_id, status, office_id, role, admin_notes)
        return jsonify({
            "status": "success",
            "message": f"Request {status.lower()} successfully",
            "data": updated_data
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500