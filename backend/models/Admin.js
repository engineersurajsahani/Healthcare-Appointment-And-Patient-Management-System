const mongoose = require('mongoose');

const AdminSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    department: {
        type: String,
        default: 'Operations'
    },
    permissions: {
        type: [String],
        default: ['MANAGE_USERS', 'VIEW_APPOINTMENTS', 'VIEW_AUDIT_LOGS']
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Admin', AdminSchema);
