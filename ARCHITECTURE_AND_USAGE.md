# Employee Attendance System - Architecture & Usage Guide

This system is divided into three distinct but fully integrated codebases. This document explains the purpose of each component and how the system is used from both the Employee (User) and Administrator perspectives.

---

## 1. The Backend Server (`emp_att_back`)
**Technology:** Python (Flask)

### Functionality
The backend acts as the central brain and security checkpoint of the entire architecture. It does not have a user interface. Instead, it exposes secure REST API endpoints that the mobile app and admin dashboard communicate with.
- **Security & Validation:** Enforces security by validating Firebase JWT authentication tokens for every request to ensure users are who they claim to be.
- **Database Operations:** Uses the Firebase Admin SDK to securely read and write data to the Firestore NoSQL database (handling attendance logs, leave requests, employee records, and office locations).
- **Media Management:** Communicates with Cloudinary to process and store profile images during employee registration.

---

## 2. The Admin Dashboard (`emp_att_admin_front`)
**Technology:** React (Vite)

### Functionality
A responsive web application designed exclusively for the company's human resources or administrative staff. It communicates securely with the backend API.

### How to use it (Admin Perspective)
1. **Login:** Admins log into the dashboard using an authorized admin email and password.
2. **Registration Management:** When a new employee downloads the mobile app and registers, their account is placed in a "Pending" state. The admin uses the **Registrations** tab to review the request, assign the employee to a specific office, grant them a role, and click **Accept**. This action automatically triggers the backend to create the employee's official account.
3. **Office Geofencing:** Admins use the **Office Data** tab to manage company locations. They can define the exact latitude, longitude, and geofence radius (in meters) for an office. They also define the strict Check-In and Check-Out time windows. 
4. **Leave Management:** Employees submit leave requests from their phones. Admins use the **Leave Requests** tab to review the reason and dates, and click Approve or Reject.
5. **Analytics:** The **Analytics** tab provides a high-level overview of office health, showing attendance percentages, late arrivals, and approved leaves month-by-month. Clicking on a specific month opens a detailed day-by-day view for any selected employee.

---

## 3. The Mobile Application (`emp_att_app`)
**Technology:** Flutter

### Functionality
The client-facing mobile application installed on the employees' iOS or Android devices. It handles location services, UI state, and API communication.

### How to use it (User / Employee Perspective)
1. **Onboarding:** A new employee opens the app, navigates to the Registration screen, and fills out their details (Name, Email, Phone, and Profile Picture). They submit the request and must wait for Admin approval.
2. **Login & Profile:** Once approved, the employee logs in with their email and the default password (e.g. `Password@123`). The home screen greets them with their profile picture and their current assigned office details.
3. **Marking Attendance:** To check in for work, the employee navigates to the **Mark Attendance** screen. 
   - The app actively queries the phone's GPS to get their current coordinates.
   - The app verifies these coordinates against the Geofence radius of their assigned office.
   - The app verifies the current time against the office's allowed Check-In/Check-Out window.
   - If all checks pass, the employee successfully logs their attendance.
4. **Requesting Leave:** If an employee is sick or needs time off, they navigate to the **Leave** screen. They select the dates, write a reason, and submit it for admin review. They can also view the history of their past leave requests and their current approval status (Pending/Approved/Rejected).
5. **Viewing History:** Employees can check their own attendance history via the app to ensure their check-ins were properly recorded.
