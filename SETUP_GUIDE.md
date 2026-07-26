# System Setup Guide: Firebase & Cloudinary

This guide outlines the steps required to configure the third-party services (Firebase and Cloudinary) required by the Employee Attendance System.

---

## 1. Cloudinary Setup (Image Storage)
Cloudinary is used to store employee profile pictures securely in the cloud.

1. **Create an Account**: Go to [cloudinary.com](https://cloudinary.com/) and sign up for a free account.
2. **Access Dashboard**: Once logged in, navigate to your primary Dashboard or Programmable Media section.
3. **Retrieve Credentials**: Locate your Product Environment Credentials. You will need three specific values:
   - Cloud Name
   - API Key
   - API Secret
4. **Configure Backend**: Open the `.env` file located in the `emp_att_back/` directory and update the following variables:
   ```env
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```

---

## 2. Firebase Setup (Authentication & Database)
Firebase handles both our user authentication (Firebase Auth) and our NoSQL database (Firestore).

### Step A: Project Creation
1. Go to the [Firebase Console](https://console.firebase.google.com/) and click **Add project**.
2. Follow the prompts to create your new project (you can disable Google Analytics if you don't need it).

### Step B: Enable Authentication
1. On the left sidebar, click **Build** > **Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, click **Email/Password**.
4. Toggle **Enable** and save. 

### Step C: Enable Firestore Database
1. On the left sidebar, click **Build** > **Firestore Database**.
2. Click **Create database**.
3. Choose a location close to your users and start in **Production mode**.

### Step D: Backend Configuration (Service Account)
The Python backend needs administrative access to create users and write to the database.
1. In the Firebase Console, click the **Gear Icon** (Project settings) next to "Project Overview".
2. Navigate to the **Service accounts** tab.
3. Click **Generate new private key**.
4. This will download a JSON file. Rename this file to `serviceAccountKey.json`.
5. Place this `serviceAccountKey.json` file directly inside the `emp_att_back/` folder.

**Note:** Never commit `serviceAccountKey.json` to public version control (like GitHub). Keep it strictly local and secure.

### Step E: React Dashboard Configuration
The React admin dashboard needs client-side configuration to authenticate users.
1. In the Firebase Console, go to **Project settings** > **General**.
2. Scroll down to "Your apps" and click the **Web** icon (`</>`).
3. Register the app (name it "Admin Dashboard").
4. Firebase will provide a `firebaseConfig` object.
5. Create a `.env` file in the `emp_att_admin_front/` directory and map the variables like so:
   ```env
   VITE_FIREBASE_API_KEY=your_api_key
   VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=your_project_id
   VITE_FIREBASE_STORAGE_BUCKET=your_project.firebasestorage.app
   VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   VITE_FIREBASE_APP_ID=your_app_id
   VITE_FIREBASE_MEASUREMENT_ID=your_measurement_id
   ```

### Step F: Flutter App Configuration
The mobile app has been scrubbed of all credentials so it can be safely shared. The person running the project must inject their own Firebase credentials using the FlutterFire CLI.
1. Open your terminal in the `emp_att_app/` directory.
2. Ensure you have the Firebase CLI installed (`npm install -g firebase-tools`) and are logged in (`firebase login`).
3. Ensure you have the FlutterFire CLI installed (`dart pub global activate flutterfire_cli`).
4. Run the configuration command:
   ```bash
   flutterfire configure --project=your_project_id
   ```
5. Follow the terminal prompts. This will automatically replace the dummy placeholders in `lib/firebase_options.dart` and `android/app/google-services.json` with your real, safe Firebase client keys.

---

## FAQ: Do we need a script to setup Firestore Collections?
**No.** Firestore is a NoSQL database. Unlike SQL databases (like MySQL or PostgreSQL) which require you to run schema migration scripts to create tables and define columns, Firestore automatically creates collections and documents on-the-fly.

When the backend (or frontend) writes the very first document to the `employees`, `attendance`, `offices`, or `registration_requests` collections, Firestore will instantly auto-generate those collections. No explicit setup script is required!
