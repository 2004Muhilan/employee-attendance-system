from src.services.firebase_service import db

def get_office_details(office_id):
    """
    Fetches the geofence configuration for a specific office ID.
    """
    try:
        # Query the office_locations collection
        # We assume the document ID is the office_id as per your schema design
        doc_ref = db.collection('office_locations').document(office_id)
        doc = doc_ref.get()

        if not doc.exists:
            return {"error": f"Office configuration not found for ID: {office_id}"}

        data = doc.to_dict()

        # Extract only necessary fields for the frontend map
        return {
            "name": data.get("name"),
            "latitude": data.get("location", {}).get("latitude"),
            "longitude": data.get("location", {}).get("longitude"),
            "radius": data.get("geofence_radius_meters", 100), # Default to 100m if missing
            "address": data.get("address"),
            "check_in_start": data.get("check_in_start", "08:00"),
            "check_in_end": data.get("check_in_end", "10:00"),
            "check_out_start": data.get("check_out_start", "17:00"),
            "check_out_end": data.get("check_out_end", "20:00"),
        }

    except Exception as e:
        print(f"Error fetching office details: {e}")
        return {"error": "Internal Database Error"}