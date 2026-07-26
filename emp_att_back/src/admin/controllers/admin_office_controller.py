# 1. Import 'request' from flask
from flask import Blueprint, jsonify, request
from src.admin.services.admin_office_service import get_all_offices, update_office_data
from src.admin.services.admin_auth_service import admin_required

admin_office_bp = Blueprint('admin_office', __name__)

@admin_office_bp.route('/offices', methods=['GET'])
@admin_required
def get_offices():
    try:
        offices = get_all_offices()
        return jsonify({
            "status": "success",
            "data": offices
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

# 2. Add the PUT endpoint for updating
@admin_office_bp.route('/offices/<office_id>', methods=['PUT'])
@admin_required
def update_office(office_id):
    data = request.get_json()
    
    try:
        updated_data = update_office_data(office_id, data)
        return jsonify({
            "status": "success",
            "message": "Office updated successfully",
            "data": updated_data
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500