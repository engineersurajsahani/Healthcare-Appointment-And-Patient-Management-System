const mongoose = require('mongoose');

const DoctorSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    specialization: {
        type: String,
        default: 'General Physician'
    },
    qualification: {
        type: String,
        default: 'MBBS'
    },
    experience: {
        type: Number,
        default: 0
    },
    approvedByAdmin: {
        type: Boolean,
        default: false
    },
    availability: [
        {
            day: String, // e.g., "Monday"
            slots: [String] // e.g., ["09:00-09:30", "09:30-10:00"]
        }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Doctor', DoctorSchema);
