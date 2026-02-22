const mongoose = require('mongoose');

const MedicalRecordSchema = new mongoose.Schema({
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
    appointmentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Appointment',
        required: true
    },
    diagnosis: {
        type: String, // Value should be encrypted before saving
        required: true
    },
    prescription: {
        type: String, // Value should be encrypted before saving
        required: true
    },
    notes: {
        type: String, // Value should be encrypted before saving
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('MedicalRecord', MedicalRecordSchema);
