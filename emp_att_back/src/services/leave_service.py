from datetime import datetime
from src.services.firebase_service import db

def create_leave_request_in_db(data):
    try:
        leave_data = {
            "eid": data.get("eid"),
            "leave_type": data.get("leave_type"),
            "start_date": data.get("start_date"),
            "end_date": data.get("end_date"),
            "reason": data.get("reason"),
            "status": "Pending",
            "applied_on": datetime.utcnow(),
            "total_days": data.get("total_days")
        }
        
        doc_ref = db.collection("leave_requests").document()
        doc_ref.set(leave_data)
        
        return {"success": True, "message": "Leave request submitted successfully", "id": doc_ref.id}
    except Exception as e:
        print(f"Error creating leave request: {e}")
        return {"success": False, "message": "Failed to create leave request."}

def get_employee_leave_requests(eid):
    """
    Retrieves all leave requests for a specific employee by ID.
    """
    try:
        # Query Firestore for documents matching the eid
        docs = db.collection("leave_requests").where("eid", "==", eid).stream()
        
        leave_history = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            
            # Firestore timestamps need to be converted to strings for JSON serialization
            if 'applied_on' in data and data['applied_on']:
                data['applied_on'] = data['applied_on'].strftime('%Y-%m-%d %H:%M:%S')
                
            leave_history.append(data)
            
        # Sort locally by 'applied_on' descending (newest first) to avoid requiring a Firebase Composite Index setup
        leave_history.sort(key=lambda x: x.get('applied_on', ''), reverse=True)
        
        return {"success": True, "data": leave_history}
        
    except Exception as e:
        print(f"Error fetching leave history: {e}")
        return {"success": False, "message": "Failed to fetch leave history."}