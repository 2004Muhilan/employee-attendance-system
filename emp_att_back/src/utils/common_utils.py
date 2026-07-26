from datetime import datetime
import pytz
import math

# Define IST Timezone
IST = pytz.timezone('Asia/Kolkata')

def get_current_ist_time():
    """Returns the current time in IST."""
    return datetime.now(IST)

def get_today_str():
    """Returns today's date as YYYY-MM-DD in IST."""
    return get_current_ist_time().strftime('%Y-%m-%d')

def get_month_str():
    """Returns current month as YYYY-MM in IST."""
    return get_current_ist_time().strftime('%Y-%m')

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Haversine formula to calculate distance (in meters) between two points.
    """
    R = 6371000  # Radius of Earth in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = math.sin(delta_phi / 2)**2 + \
        math.cos(phi1) * math.cos(phi2) * \
        math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c