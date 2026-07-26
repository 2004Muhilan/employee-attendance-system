from src.services.firebase_service import db

def get_all_leave_requests():
    try:
        # Fetch all leave requests, ordered by most recent first
        docs = db.collection('leave_requests').order_by('applied_on', direction='DESCENDING').stream()
        
        requests_list = []
        for doc in docs:
            data = doc.to_dict()
            data['id'] = doc.id
            
            # Firestore returns datetime objects, safely convert to ISO string
            if 'applied_on' in data and data['applied_on']:
                data['applied_on'] = data['applied_on'].isoformat()
                
            requests_list.append(data)
            
        return requests_list
    except Exception as e:
        raise Exception(f"Failed to fetch leave requests: {str(e)}")

def update_leave_status(request_id, status):
    try:
        doc_ref = db.collection('leave_requests').document(request_id)
        if not doc_ref.get().exists:
            raise Exception("Leave request not found")
            
        # Update only the status
        update_data = {"status": status}
        doc_ref.update(update_data)
        
        return update_data
    except Exception as e:
        raise Exception(f"Failed to update leave request: {str(e)}")