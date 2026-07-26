import React, { useState, useEffect, useMemo } from 'react';
import './Analytics.css';
import { useNavigate } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from './firebase';
import { API_BASE_URL, getAuthHeaders } from './config';

const Analytics = () => {
    const navigate = useNavigate();
    const [adminName, setAdminName] = useState("Loading...");

    // Data States
    const [employees, setEmployees] = useState([]);
    const [attendance, setAttendance] = useState([]);
    const [leaveRequests, setLeaveRequests] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [errorMsg, setErrorMsg] = useState("");

    // Control States
    const [viewMode, setViewMode] = useState('office'); // 'office' or 'employee'
    const [timeFrame, setTimeFrame] = useState('monthly'); // 'monthly' or 'yearly'
    const [selectedEid, setSelectedEid] = useState('');
    
    // Modal State for Day-wise view
    const [selectedDetailPeriod, setSelectedDetailPeriod] = useState(null);

    // 1. Auth Check & Fetching Data
    useEffect(() => {
        const storedToken = localStorage.getItem('adminToken');
        const storedData = localStorage.getItem('adminData');

        if (!storedToken || !storedData) {
            navigate('/login');
            return;
        }

        const parsedData = JSON.parse(storedData);
        setAdminName(parsedData.full_name || "Admin");

        const fetchAllData = async () => {
            try {
                // Fetch Employees, Attendance, and Leaves simultaneously
                const headers = getAuthHeaders();
                const [empRes, attRes, leaveRes] = await Promise.all([
                    fetch(`${API_BASE_URL}/admin/employees`, { headers }),
                    fetch(`${API_BASE_URL}/admin/attendance`, { headers }),
                    fetch(`${API_BASE_URL}/admin/leave-requests`, { headers })
                ]);

                const empData = await empRes.json();
                const attData = await attRes.json();
                const leaveData = await leaveRes.json();

                if (empData.status === 'success') {
                    setEmployees(empData.data);
                    if (empData.data.length > 0) setSelectedEid(empData.data[0].employee_id);
                }
                if (attData.status === 'success') setAttendance(attData.data);
                if (leaveData.status === 'success') setLeaveRequests(leaveData.data);

            } catch (error) {
                console.error("Fetch Error:", error);
                setErrorMsg("Cannot connect to server to load analytics.");
            } finally {
                setIsLoading(false);
            }
        };

        fetchAllData();
    }, [navigate]);

    // 2. Data Processing Logic for Summary Table
    const displayData = useMemo(() => {
        if (!attendance.length && !leaveRequests.length) return [];

        let filteredAttendance = attendance;
        let filteredLeaves = leaveRequests.filter(lr => lr.status === 'Approved');

        if (viewMode === 'employee') {
            if (!selectedEid) return [];
            filteredAttendance = filteredAttendance.filter(a => a.eid === selectedEid);
            filteredLeaves = filteredLeaves.filter(lr => lr.eid === selectedEid);
        }

        const groups = {}; 

        filteredAttendance.forEach(record => {
            if (!record.date) return;
            const year = record.date.substring(0, 4);
            const monthStr = record.date.substring(0, 7);
            const key = timeFrame === 'monthly' ? monthStr : year;

            if (!groups[key]) groups[key] = { presents: 0, lates: 0, leaveDays: 0, periodRaw: key };
            
            groups[key].presents += 1;
            if (record.is_late) groups[key].lates += 1;
        });

        filteredLeaves.forEach(req => {
            if (!req.start_date) return;
            const year = req.start_date.substring(0, 4);
            const monthStr = req.start_date.substring(0, 7);
            const key = timeFrame === 'monthly' ? monthStr : year;

            if (!groups[key]) groups[key] = { presents: 0, lates: 0, leaveDays: 0, periodRaw: key };
            
            groups[key].leaveDays += parseInt(req.total_days || 0, 10);
        });

        const result = Object.values(groups).map(g => {
            let periodName = g.periodRaw;
            
            if (timeFrame === 'monthly') {
                const [y, m] = g.periodRaw.split('-');
                const dateObj = new Date(y, parseInt(m) - 1);
                periodName = dateObj.toLocaleString('default', { month: 'long', year: 'numeric' });
            }

            const totalWorkingDays = g.presents + g.leaveDays;
            const attPercent = totalWorkingDays > 0 ? Math.round((g.presents / totalWorkingDays) * 100) : 0;

            return {
                periodRaw: g.periodRaw,
                period: periodName,
                attendance: attPercent,
                leaves: g.leaveDays,
                late: g.lates
            };
        });

        result.sort((a, b) => b.periodRaw.localeCompare(a.periodRaw));
        return result;
    }, [attendance, leaveRequests, viewMode, timeFrame, selectedEid]);

    // 3. Day-wise detail logic for modal
    const dailyDetails = useMemo(() => {
        if (!selectedDetailPeriod || !selectedEid) return [];

        const employee = employees.find(e => e.employee_id === selectedEid);
        if (!employee) return [];

        // Get the string formatted date of employee creation (e.g., "2026-01-31")
        const createdDateStr = employee.created_at ? employee.created_at.substring(0, 10) : "1970-01-01";
        
        const [year, month] = selectedDetailPeriod.split('-');
        const daysInMonth = new Date(year, parseInt(month), 0).getDate();
        
        const empAttendance = attendance.filter(a => a.eid === selectedEid);
        const empLeaves = leaveRequests.filter(lr => lr.eid === selectedEid && lr.status === 'Approved');

        const today = new Date();
        const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;

        const details = [];

        for (let d = 1; d <= daysInMonth; d++) {
            const dateStr = `${year}-${month}-${String(d).padStart(2, '0')}`;

            // Check if before joining date
            if (dateStr < createdDateStr) continue;

            // Check if future date
            if (dateStr > todayStr) continue;

            const dateObj = new Date(year, parseInt(month) - 1, d);
            const dayOfWeek = dateObj.getDay(); 

            // Priority 1: Weekend
            if (dayOfWeek === 0 || dayOfWeek === 6) {
                details.push({ date: dateStr, dateObj, status: 'Weekend', label: 'Weekend' });
                continue;
            }

            // Priority 2: Present (Attendance record exists)
            const attRecord = empAttendance.find(a => a.date === dateStr);
            if (attRecord) {
                details.push({ 
                    date: dateStr, 
                    dateObj, 
                    status: 'Present', 
                    label: attRecord.is_late ? 'Present (Late)' : 'Present' 
                });
                continue;
            }

            // Priority 3: Approved Leave
            const leaveRecord = empLeaves.find(lr => dateStr >= lr.start_date && dateStr <= lr.end_date);
            if (leaveRecord) {
                details.push({ date: dateStr, dateObj, status: 'Leave', label: `Leave (${leaveRecord.leave_type})` });
                continue;
            }

            // Otherwise Absent
            details.push({ date: dateStr, dateObj, status: 'Absent', label: 'Absent' });
        }

        // Sort descending
        return details.sort((a, b) => b.date.localeCompare(a.date));
    }, [selectedDetailPeriod, selectedEid, employees, attendance, leaveRequests]);


    // UI Navigation & Logout
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

    const handleRowClick = (periodRaw) => {
        if (viewMode === 'employee' && timeFrame === 'monthly') {
            setSelectedDetailPeriod(periodRaw);
        }
    };

    const formatDetailDate = (dateObj) => {
        return dateObj.toLocaleDateString('en-IN', { weekday: 'short', month: 'short', day: 'numeric' });
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
                    <button className="nav-link" onClick={() => handleNavClick('/leave-requests')}>Leave Requests</button>
                    <button className="nav-link active" onClick={() => handleNavClick('/analytics')}>Analytics</button>
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
                        <h2 className="page-title">Performance & Analytics</h2>
                        <p className="page-subtitle">Track attendance trends, punctuality, and leave patterns.</p>
                    </div>

                    <div className="filter-controls">
                        {/* Scope Toggle */}
                        <div className="filter-group">
                            <label>Data Scope:</label>
                            <div className="toggle-group">
                                <button
                                    className={`toggle-btn ${viewMode === 'office' ? 'active' : ''}`}
                                    onClick={() => { setViewMode('office'); setSelectedDetailPeriod(null); }}
                                >
                                    Office View
                                </button>
                                <button
                                    className={`toggle-btn ${viewMode === 'employee' ? 'active' : ''}`}
                                    onClick={() => setViewMode('employee')}
                                >
                                    Employee View
                                </button>
                            </div>
                        </div>

                        {/* Dynamic Employee Dropdown */}
                        <div className="filter-group">
                            <label>Select Employee:</label>
                            <select
                                className="filter-dropdown"
                                value={selectedEid}
                                onChange={(e) => { setSelectedEid(e.target.value); setSelectedDetailPeriod(null); }}
                                disabled={viewMode !== 'employee'}
                            >
                                {employees.map((emp) => (
                                    <option key={emp.employee_id} value={emp.employee_id}>
                                        {emp.full_name} ({emp.employee_id})
                                    </option>
                                ))}
                            </select>
                        </div>

                        {/* Time Frame Toggle */}
                        <div className="filter-group">
                            <label>Time Frame:</label>
                            <div className="toggle-group">
                                <button
                                    className={`toggle-btn ${timeFrame === 'monthly' ? 'active' : ''}`}
                                    onClick={() => { setTimeFrame('monthly'); setSelectedDetailPeriod(null); }}
                                >
                                    Monthly
                                </button>
                                <button
                                    className={`toggle-btn ${timeFrame === 'yearly' ? 'active' : ''}`}
                                    onClick={() => { setTimeFrame('yearly'); setSelectedDetailPeriod(null); }}
                                >
                                    Yearly
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                {/* --- DATA TABLE CARD --- */}
                <div className="data-card">
                    <div className="table-header">
                        <h3>
                            {viewMode === 'office' ? 'Office-Wide Attendance Summary' : 'Individual Attendance Summary'}
                            <span className="subtitle-sm"> ({timeFrame === 'monthly' ? 'Month by Month' : 'Year by Year'})</span>
                        </h3>
                    </div>
                    <div className="table-responsive">
                        <table className="data-table">
                            <thead>
                                <tr>
                                    <th>Period</th>
                                    <th>Attendance %</th>
                                    <th>Leaves Taken</th>
                                    <th>Late Check-ins</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                {isLoading ? (
                                    <tr><td colSpan="5" style={{ textAlign: 'center', padding: '20px' }}>Loading analytics...</td></tr>
                                ) : errorMsg ? (
                                    <tr><td colSpan="5" style={{ textAlign: 'center', color: 'red', padding: '20px' }}>{errorMsg}</td></tr>
                                ) : displayData.length === 0 ? (
                                    <tr><td colSpan="5" style={{ textAlign: 'center', padding: '20px' }}>No records found for the selected filters.</td></tr>
                                ) : (
                                    displayData.map((row, index) => (
                                        <tr 
                                            key={index} 
                                            className="table-row-hover"
                                            onClick={() => handleRowClick(row.periodRaw)}
                                            style={{ cursor: (viewMode === 'employee' && timeFrame === 'monthly') ? 'pointer' : 'default' }}
                                        >
                                            <td>
                                                <strong>{row.period}</strong>
                                                {viewMode === 'employee' && timeFrame === 'monthly' && (
                                                    <div style={{ fontSize: '11px', color: '#2196f3', marginTop: '4px' }}>Click to view days</div>
                                                )}
                                            </td>
                                            <td>
                                                <div className="attendance-cell">
                                                    <span className="att-percentage">{row.attendance}%</span>
                                                    <div className="progress-bar-bg">
                                                        <div
                                                            className={`progress-bar-fill ${row.attendance < 90 ? 'bg-warning' : 'bg-success'}`}
                                                            style={{ width: `${row.attendance}%` }}
                                                        ></div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>{row.leaves}</td>
                                            <td>
                                                <span className={row.late > 10 ? 'text-red font-bold' : ''}>
                                                    {row.late}
                                                </span>
                                            </td>
                                            <td>
                                                {row.attendance >= 90 ? (
                                                    <span className="status-badge status-approved">Healthy</span>
                                                ) : (
                                                    <span className="status-badge status-rejected">Needs Attention</span>
                                                )}
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>

            </main>

            {/* --- DAY-WISE DETAILS MODAL --- */}
            {selectedDetailPeriod && (
                <div className="modal-overlay" onClick={() => setSelectedDetailPeriod(null)}>
                    <div className="modal-content" style={{ width: '500px', maxHeight: '80vh', display: 'flex', flexDirection: 'column' }} onClick={(e) => e.stopPropagation()}>
                        <button className="modal-close" onClick={() => setSelectedDetailPeriod(null)}>✕</button>
                        <h2 style={{ marginTop: 0, color: '#212121', fontSize: '20px', marginBottom: '16px' }}>
                            Daily Attendance: {
                                new Date(selectedDetailPeriod.split('-')[0], parseInt(selectedDetailPeriod.split('-')[1]) - 1)
                                .toLocaleString('default', { month: 'long', year: 'numeric' })
                            }
                        </h2>
                        
                        <div style={{ overflowY: 'auto', flex: 1, paddingRight: '8px' }}>
                            <table className="data-table" style={{ width: '100%' }}>
                                <thead>
                                    <tr>
                                        <th style={{ position: 'sticky', top: 0, background: '#fafafa', zIndex: 1 }}>Date</th>
                                        <th style={{ position: 'sticky', top: 0, background: '#fafafa', zIndex: 1 }}>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {dailyDetails.length === 0 ? (
                                        <tr><td colSpan="2" style={{ textAlign: 'center', padding: '20px' }}>No records available for this period.</td></tr>
                                    ) : (
                                        dailyDetails.map((day, idx) => (
                                            <tr key={idx}>
                                                <td>{formatDetailDate(day.dateObj)}</td>
                                                <td>
                                                    <span style={{
                                                        padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 'bold',
                                                        backgroundColor: day.status === 'Present' ? '#e8f5e9' : day.status === 'Leave' ? '#fff3e0' : day.status === 'Weekend' ? '#f5f5f5' : '#ffebee',
                                                        color: day.status === 'Present' ? '#2e7d32' : day.status === 'Leave' ? '#e65100' : day.status === 'Weekend' ? '#616161' : '#c62828'
                                                    }}>
                                                        {day.label}
                                                    </span>
                                                </td>
                                            </tr>
                                        ))
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Analytics;