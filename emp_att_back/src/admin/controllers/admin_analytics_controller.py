from flask import Blueprint, jsonify
from src.admin.services.admin_analytics_service import get_all_employees, get_all_attendance
from src.admin.services.admin_auth_service import admin_required

admin_analytics_bp = Blueprint('admin_analytics', __name__)

@admin_analytics_bp.route('/employees', methods=['GET'])
@admin_required
def get_employees():
    try:
        employees = get_all_employees()
        return jsonify({
            "status": "success",
            "data": employees
        }), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@admin_analytics_bp.route('/attendance', methods=['GET'])
@admin_required
def get_attendance():
    try:
        attendance = get_all_attendance()
        return jsonify({
            "status": "success",
            "data": attendance
        }), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500