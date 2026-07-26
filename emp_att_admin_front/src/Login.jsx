import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from './firebase'; // Import auth from the file we just made
import { API_BASE_URL } from './config';
import './Login.css';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();
        setIsLoading(true);
        setErrorMsg('');

        try {
            // 1. Log in securely directly with Firebase from the browser
            const userCredential = await signInWithEmailAndPassword(auth, email, password);
            const user = userCredential.user;

            // 2. Extract the secure session token
            const idToken = await user.getIdToken();

            // 3. Send ONLY the token to your Flask backend to verify admin status
            const response = await fetch(`${API_BASE_URL}/admin/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ id_token: idToken }), // <--- Only sending token!
            });

            const result = await response.json();

            if (response.ok && result.status === 'success') {
                // 4. Save token and admin details to local storage
                localStorage.setItem('adminToken', idToken);
                localStorage.setItem('adminData', JSON.stringify(result.data.admin_data));
                
                // Navigate to the Dashboard
                navigate('/');
            } else {
                setErrorMsg(result.message || 'Access denied. You are not an admin.');
                // Optionally sign them out of Firebase if they aren't an admin
                auth.signOut();
            }
        } catch (error) {
            console.error("Login Error:", error);
            // Catch Firebase errors (wrong password, user not found, etc.)
            setErrorMsg(error.message || "Invalid email or password.");
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="login-container">
            <div className="login-wrapper">

                {/* Branding Section */}
                <div className="login-header">
                    <div className="logo-icon">
                        <svg viewBox="0 0 24 24" width="96" height="96" fill="currentColor">
                            <path d="M12 7V3H2v18h20V7H12zM6 19H4v-2h2v2zm0-4H4v-2h2v2zm0-4H4V9h2v2zm0-4H4V5h2v2zm4 12H8v-2h2v2zm0-4H8v-2h2v2zm0-4H8V9h2v2zm0-4H8V5h2v2zm10 12h-8v-2h2v-2h-2v-2h2v-2h-2V9h8v10zm-2-8h-2v2h2v-2zm0 4h-2v2h2v-2z" />
                        </svg>
                    </div>
                    <h1 className="company-name">Defab Engineering</h1>
                    <p className="admin-subtitle">Employee Management Admin Portal</p>
                </div>

                {/* The Login Card */}
                <div className="login-card">
                    {/* Display Error Message if it exists */}
                    {errorMsg && <div style={{ color: 'red', marginBottom: '15px', textAlign: 'center', fontSize: '14px' }}>{errorMsg}</div>}

                    <form onSubmit={handleLogin} className="login-form">
                        <div className="input-group">
                            <input
                                type="email"
                                placeholder="Email Address"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                            />
                        </div>

                        <div className="input-group">
                            <input
                                type="password"
                                placeholder="Password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                            />
                        </div>

                        <button type="submit" className="login-button" disabled={isLoading}>
                            {isLoading ? <span className="spinner"></span> : 'Sign In'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default Login;