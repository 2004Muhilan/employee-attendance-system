import React, { useState, useEffect } from 'react';
import './RegistrationRequests.css';
import { useNavigate } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from './firebase';
import { API_BASE_URL, getAuthHeaders } from './config';

const RegistrationRequests = () => {
    const navigate = useNavigate();
    
    // Core States
    const [adminName, setAdminName] = useState("Loading...");
    const [requests, setRequests] = useState([]);
    const [offices, setOffices] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [errorMsg, setErrorMsg] = useState("");
    
    // Object to track row inputs dynamically: { id: { office_id: '', role: '', admin_notes: '' } }
    const [rowInputs, setRowInputs] = useState({});

    // Modal States
    const [selectedReq, setSelectedReq] = useState(null);
    const [isModalOpen, setIsModalOpen] = useState(false);

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

        // Fetch Offices
        const fetchOffices = async () => {
            try {
                const response = await fetch(`${API_BASE_URL}/admin/offices`, {
                    headers: getAuthHeaders()
                });
                const result = await response.json();
                if (response.ok && result.status === 'success') {
                    setOffices(result.data);
                }
            } catch (error) {
                console.error("Failed to fetch offices:", error);
            }
        };

        // Fetch Registration Requests
        const fetchRequests = async () => {
            try {
                const response = await fetch(`${API_BASE_URL}/admin/registration-requests`, {
                    headers: getAuthHeaders()
                });
                const result = await response.json();

                if (response.ok && result.status === 'success') {
                    setRequests(result.data);
                    
                    // Initialize input states for each row fetched
                    const initialInputs = {};
                    result.data.forEach(req => {
                        initialInputs[req.id] = {
                            office_id: req.office_id || "",
                            role: req.role || "",
                            admin_notes: req.admin_notes || ""
                        };
                    });
                    setRowInputs(initialInputs);
                } else {
                    setErrorMsg(result.message || "Failed to fetch requests.");
                }
            } catch (error) {
                console.error("Fetch Error:", error);
                setErrorMsg("Cannot connect to server.");
            } finally {
                setIsLoading(false);
            }
        };

        fetchOffices();
        fetchRequests();
    }, [navigate]);

    // Handle Input Changes per row
    const handleInputChange = (reqId, field, value) => {
        setRowInputs(prev => ({
            ...prev,
            [reqId]: {
                ...prev[reqId],
                [field]: value
            }
        }));
    };

    // Logout & UI Actions
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

    const handleRowClick = (req) => {
        setSelectedReq(req);
        setIsModalOpen(true);
    };

    const closeModal = () => {
        setIsModalOpen(false);
        setSelectedReq(null);
    };

    // Submit Approve/Reject Action to the Backend
    const handleAction = async (e, action, reqId) => {
        e.stopPropagation();
        
        const inputs = rowInputs[reqId] || {};
        const isApproving = action === 'Accept';
        const newStatus = isApproving ? 'Approved' : 'Rejected';

        // Add a validation block for Approvals
        if (isApproving && (!inputs.office_id || !inputs.role)) {
            alert("Please select an office and type a role before approving this employee.");
            return;
        }

        try {
            const response = await fetch(`${API_BASE_URL}/admin/registration-requests/${reqId}`, {
                method: 'PUT',
                headers: getAuthHeaders(),
                body: JSON.stringify({
                    status: newStatus,
                    office_id: inputs.office_id,
                    role: inputs.role,
                    admin_notes: inputs.admin_notes
                })
            });

            const result = await response.json();

            if (response.ok && result.status === 'success') {
                // Instantly update the local UI to reflect the accepted/rejected status
                setRequests(prev => prev.map(req => 
                    req.id === reqId ? { ...req, status: newStatus, ...inputs } : req
                ));
            } else {
                alert(result.message || "Failed to update status.");
            }
        } catch (error) {
            console.error("Update Request Error:", error);
            alert("Could not connect to the server to process the update.");
        }
    };

    // Helper to format ISO timestamps
    const formatDate = (dateString) => {
        if (!dateString) return "N/A";
        const date = new Date(dateString);
        return date.toLocaleDateString('en-IN', {
            year: 'numeric', month: 'short', day: 'numeric'
        });
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
                    <button className="nav-link active" onClick={() => handleNavClick('/registrations')}>Registrations</button>
                    <button className="nav-link" onClick={() => handleNavClick('/office-data')}>Office Data</button>
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
                        <h2 className="page-title">Employee Registration Requests</h2>
                        <p className="page-subtitle">Review and manage new account applications.</p>
                    </div>

                    <div className="filter-controls">
                        <div className="filter-group">
                            <label>Filter By:</label>
                            <select defaultValue="time" className="filter-dropdown">
                                <option value="time">Time (Newest First)</option>
                                <option value="oldest">Time (Oldest First)</option>
                            </select>
                        </div>
                        <div className="filter-group">
                            <label>Status:</label>
                            <select defaultValue="all" className="filter-dropdown">
                                <option value="all">All Requests</option>
                                <option value="pending">Pending</option>
                                <option value="accepted">Accepted</option>
                                <option value="rejected">Rejected</option>
                            </select>
                        </div>
                    </div>
                </div>

                {/* --- DATA TABLE CARD --- */}
                <div className="data-card">
                    <div className="table-responsive">
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Employee Details</th>
                                    <th>Date</th>
                                    <th>Office</th>
                                    <th>Role</th>
                                    <th>Admin Comments</th>
                                    <th>Actions</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                {isLoading ? (
                                    <tr><td colSpan="7" style={{ textAlign: 'center', padding: '20px' }}>Loading requests...</td></tr>
                                ) : errorMsg ? (
                                    <tr><td colSpan="7" style={{ textAlign: 'center', color: 'red', padding: '20px' }}>{errorMsg}</td></tr>
                                ) : requests.length === 0 ? (
                                    <tr><td colSpan="7" style={{ textAlign: 'center', padding: '20px' }}>No registration requests found.</td></tr>
                                ) : (
                                    requests.map((req) => {
                                        const isPending = req.status === 'Pending';
                                        
                                        return (
                                        <tr key={req.id} onClick={() => handleRowClick(req)} className="table-row-clickable">
                                            <td>
                                                <div className="emp-details">
                                                    <strong>{req.full_name}</strong>
                                                    <span>{req.email}</span>
                                                </div>
                                            </td>
                                            <td>{formatDate(req.requested_at)}</td>
                                            
                                            {/* Dynamic Office Selection */}
                                            <td onClick={(e) => e.stopPropagation()}>
                                                <select 
                                                    className="comment-input" 
                                                    value={rowInputs[req.id]?.office_id || ""}
                                                    onChange={(e) => handleInputChange(req.id, 'office_id', e.target.value)}
                                                    disabled={!isPending}
                                                    style={{ cursor: isPending ? 'pointer' : 'not-allowed' }}
                                                >
                                                    <option value="">Select Office...</option>
                                                    {offices.map((office) => (
                                                        <option key={office.id} value={office.id}>
                                                            {office.name || office.id}
                                                        </option>
                                                    ))}
                                                </select>
                                            </td>

                                            {/* Role Assignment Input */}
                                            <td onClick={(e) => e.stopPropagation()}>
                                                <input
                                                    type="text"
                                                    className="comment-input"
                                                    placeholder="Assign Role..."
                                                    value={rowInputs[req.id]?.role || ""}
                                                    onChange={(e) => handleInputChange(req.id, 'role', e.target.value)}
                                                    disabled={!isPending}
                                                />
                                            </td>

                                            {/* Notes Input */}
                                            <td onClick={(e) => e.stopPropagation()}>
                                                <input
                                                    type="text"
                                                    className="comment-input"
                                                    placeholder="Add note..."
                                                    value={rowInputs[req.id]?.admin_notes || ""}
                                                    onChange={(e) => handleInputChange(req.id, 'admin_notes', e.target.value)}
                                                    disabled={!isPending}
                                                />
                                            </td>

                                            <td onClick={(e) => e.stopPropagation()}>
                                                <div className="action-buttons">
                                                    <button
                                                        className="btn-accept"
                                                        disabled={!isPending}
                                                        onClick={(e) => handleAction(e, 'Accept', req.id)}
                                                    >
                                                        ✓
                                                    </button>
                                                    <button
                                                        className="btn-reject"
                                                        disabled={!isPending}
                                                        onClick={(e) => handleAction(e, 'Reject', req.id)}
                                                    >
                                                        ✕
                                                    </button>
                                                </div>
                                            </td>

                                            <td>
                                                <span className={`status-badge status-${(req.status || 'pending').toLowerCase()}`}>
                                                    {req.status}
                                                </span>
                                            </td>
                                        </tr>
                                    )})
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>

            {/* --- MODAL POPUP --- */}
            {isModalOpen && selectedReq && (
                <div className="modal-overlay" onClick={closeModal}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <button className="modal-close" onClick={closeModal}>✕</button>
                        <h2 style={{marginTop: 0, color: '#212121', fontSize: '20px'}}>Employee Details</h2>
                        
                        <div className="modal-profile-section">
                            {selectedReq.profile_image_url ? (
                                <img src={selectedReq.profile_image_url} alt="Profile" className="modal-profile-img" />
                            ) : (
                                <div className="modal-profile-placeholder">
                                    {selectedReq.full_name.charAt(0)}
                                </div>
                            )}
                        </div>

                        <div className="modal-info-section">
                            <p><strong>Name:</strong> {selectedReq.full_name}</p>
                            <p><strong>Email:</strong> {selectedReq.email}</p>
                            <p><strong>Phone:</strong> {selectedReq.phone || "N/A"}</p>
                            <p><strong>Status:</strong> {selectedReq.status}</p>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default RegistrationRequests;