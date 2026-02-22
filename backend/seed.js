const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const Patient = require('./models/Patient');
const Doctor = require('./models/Doctor');
const Admin = require('./models/Admin');

dotenv.config();

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/healthcare_app');
        console.log('MongoDB Connected for Seeding');
    } catch (err) {
        console.error('MongoDB Connection Error:', err);
        process.exit(1);
    }
};

const seedData = async () => {
    await connectDB();

    try {
        // Clear existing data (optional, but cleaner for dummy data)
        // Comment these out if you want to keep existing data
        console.log('Clearing existing data...');
        await User.deleteMany({ email: { $in: ['admin@hospital.com', 'sarah@hospital.com', 'john@hospital.com', 'rahul@gmail.com', 'neha@gmail.com'] } });
        await Patient.deleteMany({});
        await Doctor.deleteMany({});
        await Admin.deleteMany({});

        console.log('Data cleared. Seeding new data...');

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt);

        // --- 1. ADMIN ---
        const adminUser = new User({
            name: 'Super Admin',
            email: 'admin@hospital.com',
            password: hashedPassword,
            role: 'admin',
            phone: '9999999999'
        });
        await adminUser.save();

        const adminProfile = new Admin({
            userId: adminUser._id,
            department: 'IT & Operations',
            permissions: ['MANAGE_USERS', 'VIEW_APPOINTMENTS', 'VIEW_AUDIT_LOGS']
        });
        await adminProfile.save();
        console.log('✅ Admin created: admin@hospital.com / password123');

        // --- 2. DOCTOR 1 (Cardiology) ---
        const doc1User = new User({
            name: 'Dr. Sarah Smith',
            email: 'sarah@hospital.com',
            password: hashedPassword,
            role: 'doctor',
            phone: '8888888888'
        });
        await doc1User.save();

        const doc1Profile = new Doctor({
            userId: doc1User._id,
            specialization: 'Cardiology',
            qualification: 'MD, FACC',
            experience: 15,
            availability: [
                { day: 'Monday', slots: ['09:00 - 09:30', '09:30 - 10:00', '10:00 - 10:30'] },
                { day: 'Wednesday', slots: ['09:00 - 09:30', '09:30 - 10:00'] }
            ]
        });
        await doc1Profile.save();
        console.log('✅ Doctor created: sarah@hospital.com (Cardiology)');

        // --- 3. DOCTOR 2 (Pediatrics) ---
        const doc2User = new User({
            name: 'Dr. John Doe',
            email: 'john@hospital.com',
            password: hashedPassword,
            role: 'doctor',
            phone: '7777777777'
        });
        await doc2User.save();

        const doc2Profile = new Doctor({
            userId: doc2User._id,
            specialization: 'Pediatrics',
            qualification: 'MBBS, MD',
            experience: 8,
            availability: [
                { day: 'Tuesday', slots: ['14:00 - 14:30', '14:30 - 15:00'] },
                { day: 'Thursday', slots: ['14:00 - 14:30', '14:30 - 15:00'] }
            ]
        });
        await doc2Profile.save();
        console.log('✅ Doctor created: john@hospital.com (Pediatrics)');

        // --- 4. PATIENT 1 ---
        const pat1User = new User({
            name: 'Rahul Kumar',
            email: 'rahul@gmail.com',
            password: hashedPassword,
            role: 'patient',
            phone: '9876543210'
        });
        await pat1User.save();

        const pat1Profile = new Patient({
            userId: pat1User._id,
            dob: new Date('1990-05-15'),
            gender: 'Male',
            bloodGroup: 'B+',
            address: '123, Main St, Delhi',
            emergencyContact: '9123456780'
        });
        await pat1Profile.save();
        console.log('✅ Patient created: rahul@gmail.com');

        // --- 5. PATIENT 2 ---
        const pat2User = new User({
            name: 'Neha Gupta',
            email: 'neha@gmail.com',
            password: hashedPassword,
            role: 'patient',
            phone: '9876543211'
        });
        await pat2User.save();

        const pat2Profile = new Patient({
            userId: pat2User._id,
            dob: new Date('1995-10-20'),
            gender: 'Female',
            bloodGroup: 'O+',
            address: '456, Park Ave, Mumbai',
            emergencyContact: '9123456789'
        });
        await pat2Profile.save();
        console.log('✅ Patient created: neha@gmail.com');

        console.log('--- SEEDING COMPLETE ---');
        process.exit(0);
    } catch (err) {
        console.error('Seeding Error:', err);
        process.exit(1);
    }
};

seedData();
