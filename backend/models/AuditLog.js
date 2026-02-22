const mongoose = require('mongoose');

const AuditLogSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    action: {
        type: String, // e.g., "VIEW_MEDICAL_RECORD"
        required: true
    },
    targetId: {
        type: mongoose.Schema.Types.ObjectId,
        required: false
    },
    ipAddress: {
        type: String,
        default: '127.0.0.1'
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('AuditLog', AuditLogSchema);
