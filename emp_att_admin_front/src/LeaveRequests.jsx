import React, { useState, useEffect } from 'react';
import './LeaveRequests.css';
import { useNavigate } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from './firebase';
import { API_BASE_URL, getAuthHeaders } from './config';

const LeaveRequests = () => {
    const navigate = useNavigate();
    
    // States
    const [adminName, setAdminName] = useState("Loading...");
    const [leaveRequests, setLeaveRequests] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [errorMsg, setErrorMsg] = useState("");

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

            // Fetch Leave Requests from Backend
        const fetchLeaveRequests = async () => {
            try {
                const response = await fetch(`${API_BASE_URL}/admin/leave-requests`, {
                    headers: getAuthHeaders()
                });
                const result = await response.json();

                if (response.ok && result.status === 'success') {
                    setLeaveRequests(result.data);
                } else {
                    setErrorMsg(result.message || "Failed to fetch leave requests.");
                }
            } catch (error) {
                console.error("Fetch Error:", error);
                setErrorMsg("Cannot connect to server.");
            } finally {
                setIsLoading(false);
            }
        };

        fetchLeaveRequests();
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

    // Update Status Action
    const handleAction = async (id, newStatus) => {
        try {
            const response = await fetch(`${API_BASE_URL}/admin/leave-requests/${id}`, {
                method: 'PUT',
                headers: getAuthHeaders(),
                body: JSON.stringify({ status: newStatus })
            });

            const result = await response.json();

            if (response.ok && result.status === 'success') {
                // Instantly update the local UI to reflect the accepted/rejected status
                setLeaveRequests(prev => prev.map(req => 
                    req.id === id ? { ...req, status: newStatus } : req
                ));
            } else {
                alert(result.message || "Failed to update status.");
            }
        } catch (error) {
            console.error("Update Request Error:", error);
            alert("Could not connect to the server to process the update.");
        }
    };

    // Helper to format ISO timestamps for "Applied On"
    const formatDate = (dateString) => {
        if (!dateString) return "N/A";
        const date = new Date(dateString);
        return date.toLocaleDateString('en-IN', {
            year: 'numeric', month: 'short', day: 'numeric',
            hour: '2-digit', minute: '2-digit'
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
                    <button className="nav-link" onClick={() => handleNavClick('/registrations')}>Registrations</button>
                    <button className="nav-link" onClick={() => handleNavClick('/office-data')}>Office Data</button>
                    <button className="nav-link active" onClick={() => handleNavClick('/leave-requests')}>Leave Requests</button>
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
                        <h2 className="page-title">Employee Leave Requests</h2>
                        <p className="page-subtitle">Review, approve, or reject employee time-off applications.</p>
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
                                <option value="approved">Approved</option>
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
                                    <th>Employee Info</th>
                                    <th>Leave Type & Reason</th>
                                    <th>Duration</th>
                                    <th>Applied On</th>
                                    <th>Status</th>
                                    <th style={{ textAlign: 'center' }}>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                {isLoading ? (
                                    <tr><td colSpan="6" style={{ textAlign: 'center', padding: '20px' }}>Loading requests...</td></tr>
                                ) : errorMsg ? (
                                    <tr><td colSpan="6" style={{ textAlign: 'center', color: 'red', padding: '20px' }}>{errorMsg}</td></tr>
                                ) : leaveRequests.length === 0 ? (
                                    <tr><td colSpan="6" style={{ textAlign: 'center', padding: '20px' }}>No leave requests found.</td></tr>
                                ) : (
                                    leaveRequests.map((req) => (
                                        <tr key={req.id} className="table-row-hover">
                                            {/* Employee Cell */}
                                            <td>
                                                <div className="emp-details">
                                                    <strong>{req.name || `Employee (${req.eid})`}</strong>
                                                    <span className="emp-id">{req.eid}</span>
                                                </div>
                                            </td>

                                            {/* Leave Type Cell */}
                                            <td>
                                                <div className="leave-type-cell">
                                                    <strong>{req.leave_type}</strong>
                                                    <span className="leave-reason">{req.reason}</span>
                                                </div>
                                            </td>

                                            {/* Duration Cell */}
                                            <td>
                                                <div className="duration-cell">
                                                    <span>{req.start_date} to {req.end_date}</span>
                                                    <span className="total-days">{req.total_days} Days</span>
                                                </div>
                                            </td>

                                            {/* Applied On Cell */}
                                            <td>
                                                <span className="applied-date">{formatDate(req.applied_on)}</span>
                                            </td>

                                            {/* Status Cell */}
                                            <td>
                                                <span className={`status-badge status-${(req.status || 'pending').toLowerCase()}`}>
                                                    {req.status}
                                                </span>
                                            </td>

                                            {/* Action Buttons */}
                                            <td>
                                                <div className="action-buttons-center">
                                                    <button
                                                        className="btn-accept"
                                                        disabled={req.status !== 'Pending'}
                                                        onClick={() => handleAction(req.id, 'Approved')}
                                                        title="Approve"
                                                        style={req.status !== 'Pending' ? { opacity: 0.4, cursor: 'not-allowed' } : {}}
                                                    >
                                                        ✓
                                                    </button>
                                                    <button
                                                        className="btn-reject"
                                                        disabled={req.status !== 'Pending'}
                                                        onClick={() => handleAction(req.id, 'Rejected')}
                                                        title="Reject"
                                                        style={req.status !== 'Pending' ? { opacity: 0.4, cursor: 'not-allowed' } : {}}
                                                    >
                                                        ✕
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </main>
        </div>
    );
};

export default LeaveRequests;