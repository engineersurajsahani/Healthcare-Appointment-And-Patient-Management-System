const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema({
    patientId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    doctorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    date: { // Using 'date' to match frontend, maps to 'appointmentDate' concept
        type: Date,
        required: true
    },
    timeSlot: {
        type: String,
        required: true
    },
    reason: {
        type: String,
        default: ''
    },
    status: {
        type: String,
        enum: ['Pending', 'Booked', 'Approved', 'Completed', 'Cancelled'],
        default: 'Booked'
    },
    reminded: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Appointment', AppointmentSchema);
