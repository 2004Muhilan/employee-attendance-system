from flask import Flask
from flask_cors import CORS
from src.controllers.auth_controller import auth_bp
from src.controllers.geofence_controller import geofence_bp
from src.controllers.attendance_controller import attendance_bp
from src.controllers.leave_controller import leave_bp
from src.admin.controllers.admin_auth_controller import admin_auth_bp
from src.admin.controllers.admin_registration_controller import admin_registration_bp
from src.admin.controllers.admin_office_controller import admin_office_bp
from src.admin.controllers.admin_leave_controller import admin_leave_bp
from src.admin.controllers.admin_analytics_controller import admin_analytics_bp

def create_app():
    app = Flask(__name__)
    
    # Enable CORS (Cross-Origin Resource Sharing)
    # This allows your mobile app to talk to this server
    CORS(app)

    # Register Blueprints (Routes)
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(geofence_bp, url_prefix='/geofence')
    app.register_blueprint(attendance_bp, url_prefix='/attendance')
    app.register_blueprint(leave_bp, url_prefix='/leave')

    # Admin Routes
    app.register_blueprint(admin_auth_bp, url_prefix='/admin')
    app.register_blueprint(admin_registration_bp, url_prefix='/admin')
    app.register_blueprint(admin_office_bp, url_prefix='/admin')
    app.register_blueprint(admin_leave_bp, url_prefix='/admin')
    app.register_blueprint(admin_analytics_bp, url_prefix='/admin')

    # Health Check Route (Useful for Render to know app is alive)
    @app.route('/')
    def health_check():
        return {"status": "online", "service": "Employee Attendance API"}

    return app