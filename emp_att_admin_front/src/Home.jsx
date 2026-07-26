import React, { useEffect, useState } from 'react';
import './Home.css';
import { useNavigate } from 'react-router-dom';

const Home = () => {
    const navigate = useNavigate();
    const [adminName, setAdminName] = useState("Loading...");

    // Check for login status when the component loads
    useEffect(() => {
        const storedToken = localStorage.getItem('adminToken');
        const storedData = localStorage.getItem('adminData');

        if (!storedToken || !storedData) {
            // If they are not logged in, kick them back to the login screen
            navigate('/login');
        } else {
            // Parse the stored string back into a JSON object and set the name
            const parsedData = JSON.parse(storedData);
            setAdminName(parsedData.full_name || "Admin");
        }
    }, [navigate]);

    const handleLogout = () => {
        // Clear everything out of the browser storage
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminData');
        
        // Push the user back to the login page
        navigate('/login');
    };

    const handleCardClick = (path) => navigate(path);

    return (
        <div className="home-container">
            {/* Top Navigation Bar */}
            <header className="home-header">
                <div className="header-left">
                    <div className="header-logo">
                        <svg viewBox="0 0 24 24" width="32" height="32" fill="currentColor">
                            <path d="M12 7V3H2v18h20V7H12zM6 19H4v-2h2v2zm0-4H4v-2h2v2zm0-4H4V9h2v2zm0-4H4V5h2v2zm4 12H8v-2h2v2zm0-4H8v-2h2v2zm0-4H8V9h2v2zm0-4H8V5h2v2zm10 12h-8v-2h2v-2h-2v-2h2v-2h-2V9h8v10zm-2-8h-2v2h2v-2zm0 4h-2v2h2v-2z" />
                        </svg>
                    </div>
                    <h1 className="header-title">Defab Engineering</h1>
                </div>

                <div className="header-right">
                    <div className="admin-profile">
                        <div className="admin-avatar">
                            <svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
                                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
                            </svg>
                        </div>
                        <span className="admin-name">{adminName}</span>
                    </div>
                    <button className="logout-button" onClick={handleLogout}>
                        <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor">
                            <path d="M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z" />
                        </svg>
                        Log Out
                    </button>
                </div>
            </header>

            {/* Main Content Area */}
            <main className="home-main">
                <div className="welcome-section">
                    <h2>Dashboard Overview</h2>
                    <p>Welcome back, {adminName}. Select a module to manage your workforce.</p>
                </div>

                {/* The 4 Action Cards in a single row */}
                <div className="action-cards-row">

                    {/* Card 1: Registrations */}
                    <div className="action-card" onClick={() => handleCardClick("/registrations")}>
                        <div className="card-icon-wrapper bg-blue">
                            <svg viewBox="0 0 24 24" width="36" height="36" fill="currentColor" className="text-blue">
                                <path d="M15 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm-9-2V7H4v3H1v2h3v3h2v-3h3v-2H6zm9 4c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
                            </svg>
                        </div>
                        <h3>Registration Requests</h3>
                        <p>Approve or deny new employee accounts.</p>
                    </div>

                    {/* Card 2: Office Data */}
                    <div className="action-card" onClick={() => handleCardClick("/office-data")}>
                        <div className="card-icon-wrapper bg-green">
                            <svg viewBox="0 0 24 24" width="36" height="36" fill="currentColor" className="text-green">
                                <path d="M20.5 3l-.16.03L15 5.1 9 3 3.36 4.9c-.21.07-.36.25-.36.48V20.5c0 .28.22.5.5.5l.16-.03L9 18.9l6 2.1 5.64-1.9c.21-.07.36-.25.36-.48V3.5c0-.28-.22-.5-.5-.5zM15 19l-6-2.11V5l6 2.11V19z" />
                            </svg>
                        </div>
                        <h3>Office Data</h3>
                        <p>Manage office locations and geofences.</p>
                    </div>

                    {/* Card 3: Leave Requests */}
                    <div className="action-card" onClick={() => handleCardClick("/leave-requests")}>
                        <div className="card-icon-wrapper bg-orange">
                            <svg viewBox="0 0 24 24" width="36" height="36" fill="currentColor" className="text-orange">
                                <path d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z" />
                            </svg>
                        </div>
                        <h3>Leave Requests</h3>
                        <p>Review and process employee time off.</p>
                    </div>

                    {/* Card 4: Analytics */}
                    <div className="action-card" onClick={() => handleCardClick("/analytics")}>
                        <div className="card-icon-wrapper bg-purple">
                            <svg viewBox="0 0 24 24" width="36" height="36" fill="currentColor" className="text-purple">
                                <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z" />
                            </svg>
                        </div>
                        <h3>Employee Analytics</h3>
                        <p>View attendance and performance reports.</p>
                    </div>

                </div>
            </main>
        </div>
    );
};

export default Home;