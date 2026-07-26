from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from src.services.firebase_service import db, get_employee_profile
from src.services.geofence_service import get_office_details
from src.utils.common_utils import get_current_ist_time, get_today_str, get_month_str, calculate_distance, IST
from datetime import datetime

def mark_check_in(uid, user_lat, user_lng):
    try:
        # 1. Get Employee & Office Details
        user_profile = get_employee_profile(uid)
        if not user_profile:
            return {"error": "User profile not found"}
        
        eid = user_profile.get('employee_id') # Assuming 'id' or 'employee_id'
        office_id = user_profile.get('office_id')
        
        office = get_office_details(office_id)
        if "error" in office:
            return office

        # 2. VALIDATION: Geofence (Server-Side Check)
        office_lat = office['latitude']
        office_lng = office['longitude']
        allowed_radius = office['radius']
        
        distance = calculate_distance(user_lat, user_lng, office_lat, office_lng)
        if distance > allowed_radius:
            return {"error": f"You are {int(distance)}m away from office. Please move closer."}

        # 3. VALIDATION: Time Windows (IST)
        now_ist = get_current_ist_time()
        current_time_str = now_ist.strftime('%H:%M') # HH:MM format
        today_str = get_today_str()
        
        # Check if already checked in
        doc_id = f"{eid}_{today_str}"
        doc_ref = db.collection('attendance_records').document(doc_id)
        
        if doc_ref.get().exists:
            return {"error": "You have already checked in for today."}

        # Time Logic
        # Parse office times (e.g., "09:00")
        check_in_start = office.get('check_in_start', '00:00') # default allow
        check_in_end = office.get('check_in_end', '23:59')
        
        # Check if too early
        if current_time_str < check_in_start:
            return {"error": f"Check-in not allowed yet. Starts at {check_in_start}."}

        # Check if late
        is_late = current_time_str > check_in_end

        # 4. WRITE TO DB
        data = {
            "eid": eid,
            "date": today_str,
            "month": get_month_str(),
            "status": "PRESENT",
            "is_late": is_late,
            "check_in": now_ist, # Firestore saves this as Timestamp
            "check_in_location": {"latitude": user_lat, "longitude": user_lng},
            "office_id": office_id
        }
        
        doc_ref.set(data)
        
        return {
            "message": "Check-in successful", 
            "is_late": is_late, 
            "time": current_time_str
        }

    except Exception as e:
        print(f"Check-in Error: {e}")
        return {"error": str(e)}

def mark_check_out(uid, user_lat, user_lng):
    try:
        # 1. Get User
        user_profile = get_employee_profile(uid)
        eid = user_profile.get('employee_id')
        
        today_str = get_today_str()
        doc_id = f"{eid}_{today_str}"
        doc_ref = db.collection('attendance_records').document(doc_id)
        
        doc_snap = doc_ref.get()
        if not doc_snap.exists:
            return {"error": "No check-in record found for today."}
            
        record = doc_snap.to_dict()
        
        if "check_out" in record:
             return {"error": "You have already checked out today."}

        # 2. VALIDATION: Time (Minimum work hours check could go here)
        # For now, we just log it.
        now_ist = get_current_ist_time()

        # 3. Calculate Duration
        check_in_time = record['check_in'] # Firestore Timestamp
        # Convert Firestore timestamp to Python datetime if needed, usually auto-converted
        
        # Calculate hours worked
        duration = now_ist - check_in_time
        work_hours = round(duration.total_seconds() / 3600, 2)

        # 4. UPDATE DB
        update_data = {
            "check_out": now_ist,
            "check_out_location": {"latitude": user_lat, "longitude": user_lng},
            "status": "COMPLETED",
            "work_hours": work_hours
        }
        
        doc_ref.update(update_data)
        
        return {
            "message": "Check-out successful", 
            "work_hours": work_hours
        }

    except Exception as e:
        return {"error": str(e)}

def get_user_attendance_history(uid):
    try:
        # 1. Get Employee Profile for Joining Date
        user_profile = get_employee_profile(uid)
        if not user_profile:
            return {"error": "User profile not found"}
            
        eid = user_profile.get('employee_id')
        joining_date = user_profile.get('created_at')

        # 2. Query ALL records for this employee
        # Ordered by date descending (newest first)
        docs = db.collection('attendance_records')\
            .where(filter=FieldFilter('eid', '==', eid))\
            .order_by('date', direction=firestore.Query.DESCENDING)\
            .stream()

        history = []
        for doc in docs:
            data = doc.to_dict()
            # Serialize Timestamps
            if 'check_in' in data and data['check_in']:
                data['check_in'] = data['check_in'].isoformat()
            if 'check_out' in data and data['check_out']:
                data['check_out'] = data['check_out'].isoformat()
            history.append(data)
            
        return {
            "history": history,
            "joining_date": joining_date
        }

    except Exception as e:
        return {"error": str(e)}

def get_today_status(uid):
    try:
        user_profile = get_employee_profile(uid)
        if not user_profile:
            return {"error": "User profile not found"}
            
        eid = user_profile.get('employee_id')
        today_str = get_today_str()
        
        # Check if record exists for today
        doc_id = f"{eid}_{today_str}"
        doc_ref = db.collection('attendance_records').document(doc_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            return {
                "status": "NOT_CHECKED_IN",
                "can_check_in": True,
                "can_check_out": False
            }
            
        data = doc.to_dict()
        
        if data.get('check_out'):
            return {
                "status": "COMPLETED",
                "can_check_in": False,
                "can_check_out": False,
                "check_in_time": data.get('check_in'), # Send back for UI display
                "check_out_time": data.get('check_out')
            }
            
        else:
             return {
                "status": "CHECKED_IN",
                "can_check_in": False,
                "can_check_out": True,
                "check_in_time": data.get('check_in')
            }

    except Exception as e:
        return {"error": str(e)}