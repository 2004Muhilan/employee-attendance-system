import firebase_admin
from firebase_admin import credentials, firestore, auth
import os

# Initialize Firebase Admin SDK
# We wrap this in a check to prevent "App already initialized" errors during hot reloads
if not firebase_admin._apps:
    # In production (Render), we might load this from an ENV variable, 
    # but for now, loading from the file is fine.
    cred_path = os.path.join(os.getcwd(), 'serviceAccountKey.json')
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

def verify_token_and_get_uid(id_token):
    """
    Verifies the JWT token sent from the mobile app.
    Returns the UID if valid, raises error if invalid.
    """
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token['uid']
    except Exception as e:
        print(f"Token verification failed: {e}")
        return None

def get_employee_profile(uid):
    """
    Fetches the employee document from the 'employees' collection.
    """
    try:
        doc_ref = db.collection('employees').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            return doc.to_dict()
        else:
            return None
    except Exception as e:
        print(f"Database error: {e}")
        return None