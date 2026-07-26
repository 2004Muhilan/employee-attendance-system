import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Login from './Login';
import Home from './Home';
import RegistrationRequests from './RegistrationRequests';
import OfficeData from './OfficeData';
import LeaveRequests from './LeaveRequests';
import Analytics from './Analytics';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<Home />} />
        <Route path="/registrations" element={<RegistrationRequests />} />
        <Route path="/office-data" element={<OfficeData />} />
        <Route path="/leave-requests" element={<LeaveRequests />} />
        <Route path="/analytics" element={<Analytics />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;