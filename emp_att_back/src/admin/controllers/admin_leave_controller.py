from flask import Blueprint, jsonify, request
from src.admin.services.admin_leave_service import get_all_leave_requests, update_leave_status
from src.admin.services.admin_auth_service import admin_required

admin_leave_bp = Blueprint('admin_leave', __name__)

@admin_leave_bp.route('/leave-requests', methods=['GET'])
@admin_required
def get_leave_requests():
    try:
        requests_data = get_all_leave_requests()
        return jsonify({
            "status": "success",
            "data": requests_data
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@admin_leave_bp.route('/leave-requests/<request_id>', methods=['PUT'])
@admin_required
def update_leave_request(request_id):
    data = request.get_json()
    status = data.get('status')
    
    if not status or status not in ['Approved', 'Rejected']:
        return jsonify({"status": "error", "message": "Invalid status provided."}), 400
        
    try:
        updated_data = update_leave_status(request_id, status)
        return jsonify({
            "status": "success",
            "message": f"Leave request {status.lower()} successfully",
            "data": updated_data
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500