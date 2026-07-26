import React, { useState, useEffect } from 'react';
import './OfficeData.css';
import { useNavigate } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from './firebase';
import { API_BASE_URL, getAuthHeaders } from './config';

const OfficeData = () => {
    const navigate = useNavigate();
    
    // Core States
    const [adminName, setAdminName] = useState("Loading...");
    const [offices, setOffices] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [errorMsg, setErrorMsg] = useState("");

    // Modal States
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editForm, setEditForm] = useState(null);

    // 1. Auth Check & Fetching Initial Data
    useEffect(() => {
        const storedToken = localStorage.getItem('adminToken');
        const storedData = localStorage.getItem('adminData');

        if (!storedToken || !storedData) {
            navigate('/login');
            return;
        }

        const parsedData = JSON.parse(storedData);
        setAdminName(parsedData.full_name || "Admin");

        const fetchOffices = async () => {
            try {
                const response = await fetch(`${API_BASE_URL}/admin/offices`, {
                    headers: getAuthHeaders()
                });
                const result = await response.json();

                if (response.ok && result.status === 'success') {
                    setOffices(result.data);
                } else {
                    setErrorMsg(result.message || "Failed to fetch offices.");
                }
            } catch (error) {
                console.error("Fetch Error:", error);
                setErrorMsg("Cannot connect to server.");
            } finally {
                setIsLoading(false);
            }
        };

        fetchOffices();
    }, [navigate]);

    // Logout & Navigation
    const handleNavClick = (path) => navigate(path);

    const handleLogout = async () => {
        try {
            await signOut(auth);
        } catch (error) {
            console.error("Error signing out:", error);
        }
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminData');
        navigate('/login');
    };

    // Modal Controls
    const handleEditClick = (office) => {
        // Pre-fill the form state with the selected office's current data
        setEditForm({
            office_id: office.office_id,
            name: office.name || "",
            address: office.address || "",
            check_in_start: office.check_in_start || "",
            check_in_end: office.check_in_end || "",
            check_out_start: office.check_out_start || "",
            check_out_end: office.check_out_end || "",
            geofence_radius_meters: office.geofence_radius_meters || "",
            latitude: office.location?.latitude || "",
            longitude: office.location?.longitude || ""
        });
        setIsModalOpen(true);
    };

    const closeModal = () => {
        setIsModalOpen(false);
        setEditForm(null);
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setEditForm(prev => ({ ...prev, [name]: value }));
    };

    // Submit Updates
    const handleSubmit = async (e) => {
        e.preventDefault();
        
        // Prepare payload structured for Firestore
        const payload = {
            name: editForm.name,
            address: editForm.address,
            check_in_start: editForm.check_in_start,
            check_in_end: editForm.check_in_end,
            check_out_start: editForm.check_out_start,
            check_out_end: editForm.check_out_end,
            geofence_radius_meters: parseInt(editForm.geofence_radius_meters, 10),
            location: {
                latitude: parseFloat(editForm.latitude),
                longitude: parseFloat(editForm.longitude)
            }
        };

        try {
            const response = await fetch(`${API_BASE_URL}/admin/offices/${editForm.office_id}`, {
                method: 'PUT',
                headers: getAuthHeaders(),
                body: JSON.stringify(payload)
            });

            const result = await response.json();

            if (response.ok && result.status === 'success') {
                // Update local state so UI refreshes without needing a page reload
                setOffices(prev => prev.map(o => 
                    o.office_id === editForm.office_id ? { ...o, ...payload } : o
                ));
                closeModal();
            } else {
                alert(result.message || "Failed to update office.");
            }
        } catch (error) {
            console.error("Update Error:", error);
            alert("Could not connect to the server.");
        }
    };

    return (
        <div className="admin-page-container">
            {/* --- TOP NAVIGATION BAR --- */}
            <header className="admin-navbar">
                <div className="navbar-left" onClick={() => handleNavClick('/')} style={{ cursor: 'pointer' }}>
                    <div className="navbar-logo">
                        <svg viewBox="0 0 24 24" width="28" height="28" fill="currentColor">
                            <path d="M12 7V3H2v18h20V7H12zM6 19H4v-2h2v2zm0-4H4v-2h2v2zm0-4H4V9h2v2zm0-4H4V5h2v2zm4 12H8v-2h2v2zm0-4H8v-2h2v2zm0-4H8V9h2v2zm0-4H8V5h2v2zm10 12h-8v-2h2v-2h-2v-2h2v-2h-2V9h8v10zm-2-8h-2v2h2v-2zm0 4h-2v2h2v-2z" />
                        </svg>
                    </div>
                    <h1 className="navbar-brand">Defab Engineering</h1>
                </div>

                <nav className="navbar-center">
                    <button className="nav-link" onClick={() => handleNavClick('/registrations')}>Registrations</button>
                    <button className="nav-link active" onClick={() => handleNavClick('/office-data')}>Office Data</button>
                    <button className="nav-link" onClick={() => handleNavClick('/leave-requests')}>Leave Requests</button>
                    <button className="nav-link" onClick={() => handleNavClick('/analytics')}>Analytics</button>
                </nav>

                <div className="navbar-right">
                    <div className="admin-profile-sm">
                        <span className="admin-name-sm">{adminName}</span>
                    </div>
                    <button className="logout-btn-sm" onClick={handleLogout}>Log Out</button>
                </div>
            </header>

            {/* --- MAIN CONTENT --- */}
            <main className="admin-main-content">
                <div className="page-header">
                    <div>
                        <h2 className="page-title">Office Data Management</h2>
                        <p className="page-subtitle">Manage office locations, timings, and geofence parameters.</p>
                    </div>
                </div>

                {/* --- DATA TABLE CARD --- */}
                <div className="data-card">
                    <div className="table-responsive">
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Office Info</th>
                                    <th>Address</th>
                                    <th>Check-In Window</th>
                                    <th>Check-Out Window</th>
                                    <th>Geofence (Radius & Loc)</th>
                                    <th style={{ textAlign: 'center' }}>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                {isLoading ? (
                                    <tr><td colSpan="6" style={{ textAlign: 'center', padding: '20px' }}>Loading offices...</td></tr>
                                ) : errorMsg ? (
                                    <tr><td colSpan="6" style={{ textAlign: 'center', color: 'red', padding: '20px' }}>{errorMsg}</td></tr>
                                ) : offices.length === 0 ? (
                                    <tr><td colSpan="6" style={{ textAlign: 'center', padding: '20px' }}>No office records found.</td></tr>
                                ) : (
                                    offices.map((office) => (
                                        <tr key={office.office_id} className="table-row-hover">
                                            <td>
                                                <div className="office-details">
                                                    <strong>{office.name}</strong>
                                                    <span className="office-id">{office.office_id}</span>
                                                </div>
                                            </td>
                                            <td>
                                                <div className="address-cell">{office.address}</div>
                                            </td>
                                            <td>
                                                <div className="timing-cell">
                                                    <span className="time-label">Start:</span> {office.check_in_start || "N/A"}<br/>
                                                    <span className="time-label">End:</span> {office.check_in_end || "N/A"}
                                                </div>
                                            </td>
                                            <td>
                                                <div className="timing-cell">
                                                    <span className="time-label">Start:</span> {office.check_out_start || "N/A"}<br/>
                                                    <span className="time-label">End:</span> {office.check_out_end || "N/A"}
                                                </div>
                                            </td>
                                            <td>
                                                <div className="location-cell">
                                                    <span><strong>Lat:</strong> {office.location?.latitude || "N/A"}</span>
                                                    <span><strong>Lng:</strong> {office.location?.longitude || "N/A"}</span>
                                                    <span><strong>Radius:</strong> {office.geofence_radius_meters}m</span>
                                                </div>
                                            </td>
                                            <td style={{ textAlign: 'center' }}>
                                                <button
                                                    className="btn-edit"
                                                    onClick={() => handleEditClick(office)}
                                                >
                                                    Edit
                                                </button>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>

            {/* --- EDIT MODAL POPUP --- */}
            {isModalOpen && editForm && (
                <div className="modal-overlay" onClick={closeModal}>
                    <div className="modal-content" style={{ width: '500px' }} onClick={(e) => e.stopPropagation()}>
                        <button className="modal-close" onClick={closeModal}>✕</button>
                        <h2 style={{ marginTop: 0, color: '#212121', fontSize: '20px', marginBottom: '20px' }}>
                            Edit Office: {editForm.name}
                        </h2>
                        
                        <form onSubmit={handleSubmit} className="office-form">
                            <div className="form-row">
                                <div className="form-group">
                                    <label>Office Name</label>
                                    <input required type="text" name="name" value={editForm.name} onChange={handleInputChange} />
                                </div>
                            </div>
                            
                            <div className="form-row">
                                <div className="form-group full-width">
                                    <label>Address</label>
                                    <input required type="text" name="address" value={editForm.address} onChange={handleInputChange} />
                                </div>
                            </div>

                            <div className="form-row">
                                <div className="form-group">
                                    <label>Check-In Start</label>
                                    <input required type="time" name="check_in_start" value={editForm.check_in_start} onChange={handleInputChange} />
                                </div>
                                <div className="form-group">
                                    <label>Check-In End</label>
                                    <input required type="time" name="check_in_end" value={editForm.check_in_end} onChange={handleInputChange} />
                                </div>
                            </div>

                            <div className="form-row">
                                <div className="form-group">
                                    <label>Check-Out Start</label>
                                    <input required type="time" name="check_out_start" value={editForm.check_out_start} onChange={handleInputChange} />
                                </div>
                                <div className="form-group">
                                    <label>Check-Out End</label>
                                    <input required type="time" name="check_out_end" value={editForm.check_out_end} onChange={handleInputChange} />
                                </div>
                            </div>

                            <div className="form-row">
                                <div className="form-group">
                                    <label>Latitude</label>
                                    <input required type="number" step="any" name="latitude" value={editForm.latitude} onChange={handleInputChange} />
                                </div>
                                <div className="form-group">
                                    <label>Longitude</label>
                                    <input required type="number" step="any" name="longitude" value={editForm.longitude} onChange={handleInputChange} />
                                </div>
                            </div>

                            <div className="form-row">
                                <div className="form-group">
                                    <label>Geofence Radius (meters)</label>
                                    <input required type="number" name="geofence_radius_meters" value={editForm.geofence_radius_meters} onChange={handleInputChange} />
                                </div>
                            </div>

                            <div className="modal-actions">
                                <button type="button" className="btn-cancel" onClick={closeModal}>Cancel</button>
                                <button type="submit" className="btn-submit">Save Changes</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default OfficeData;