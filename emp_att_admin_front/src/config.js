// Centralized configuration file for the React Admin Dashboard
export const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://127.0.0.1:5000';

// Helper to safely get the token headers
export const getAuthHeaders = () => {
    const token = localStorage.getItem('adminToken');
    return {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
    };
};
