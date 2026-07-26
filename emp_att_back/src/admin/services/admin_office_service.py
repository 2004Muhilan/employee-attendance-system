from src.services.firebase_service import db

def get_all_offices():
    try:
        docs = db.collection('office_locations').stream()
        offices_list = []
        for doc in docs:
            data = doc.to_dict()
            data['office_id'] = doc.id
            offices_list.append(data)
        return offices_list
    except Exception as e:
        raise Exception(f"Failed to fetch offices: {str(e)}")

def update_office_data(office_id, update_data):
    try:
        doc_ref = db.collection('office_locations').document(office_id)
        if not doc_ref.get().exists:
            raise Exception("Office not found")
            
        # Ensure correct data types before saving to Firestore
        if 'geofence_radius_meters' in update_data:
            update_data['geofence_radius_meters'] = int(update_data['geofence_radius_meters'])
            
        if 'location' in update_data:
            update_data['location'] = {
                "latitude": float(update_data['location']['latitude']),
                "longitude": float(update_data['location']['longitude'])
            }
            
        doc_ref.update(update_data)
        return update_data
        
    except Exception as e:
        raise Exception(f"Failed to update office: {str(e)}")