# Healthcare Appointment & Patient Management System - Group 11
## Team Members:
`Hanshika Anchan`
`Manas More`
`Sahil Sable`

## Tech Stack
- **Frontend**: Flutter
- **Backend**: Node.js / Express
- **Database**: MongoDB

## Setup Instructions

### Backend
1. Navigate to the `backend` folder.
2. Install dependencies: `npm install`
3. Start the server: `npm run dev` (or `node server.js`)
   - Ensure MongoDB is running locally on default port 27017.

### Frontend
1. Navigate to the `frontend` folder.
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Project Structure
- `backend/models/*.js`: Mongoose schemas for User, Doctor, Patient, Appointment, etc.
- `backend/server.js`: Express server entry point.
- `frontend/lib/screens/`: Flutter UI screens (Auth, Patient, Doctor, Admin).
- `frontend/lib/services/`: API services.
