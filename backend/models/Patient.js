const mongoose = require('mongoose');

const PatientSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    dob: {
        type: Date,
        // required: true // Made optional for initial registration simplicity
    },
    gender: {
        type: String,
        enum: ['Male', 'Female', 'Other'],
        // required: true
    },
    bloodGroup: {
        type: String
    },
    address: {
        type: String
    },
    emergencyContact: {
        type: String
    },
    documents: [
        {
            title: String,
            url: String, // Simulated upload
            date: { type: Date, default: Date.now }
        }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Patient', PatientSchema);
