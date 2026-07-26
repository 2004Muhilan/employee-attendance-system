from src.services.firebase_service import db

def get_all_employees():
    try:
        docs = db.collection('employees').stream()
        return [doc.to_dict() for doc in docs]
    except Exception as e:
        raise Exception(f"Failed to fetch employees: {str(e)}")

def get_all_attendance():
    try:
        docs = db.collection('attendance_records').stream()
        records = []
        for doc in docs:
            data = doc.to_dict()
            # Safely serialize timestamps to ISO strings
            if 'check_in' in data and data['check_in']:
                data['check_in'] = data['check_in'].isoformat()
            if 'check_out' in data and data['check_out']:
                data['check_out'] = data['check_out'].isoformat()
            records.append(data)
        return records
    except Exception as e:
        raise Exception(f"Failed to fetch attendance records: {str(e)}")