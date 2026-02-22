const express = require('express');
const router = express.Router();
const { auth, authorize } = require('../middleware/auth');
const User = require('../models/User');
const Doctor = require('../models/Doctor');
const Appointment = require('../models/Appointment');
const AuditLog = require('../models/AuditLog');

// @route   GET api/admin/stats
// @desc    Get system statistics
// @access  Private (Admin)
router.get('/stats', auth, authorize('admin'), async (req, res) => {
    try {
        const patients = await User.countDocuments({ role: 'patient' });
        const doctors = await User.countDocuments({ role: 'doctor' });
        const appointments = await Appointment.countDocuments();

        res.json({
            patients,
            doctors,
            appointments
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   GET api/admin/users
// @desc    Get all users by role query
// @access  Private (Admin)
router.get('/users', auth, authorize('admin'), async (req, res) => {
    const { role } = req.query;
    try {
        let query = {};
        if (role) query.role = role;

        // Exclude password
        const users = await User.find(query).select('-password').sort({ createdAt: -1 });
        res.json(users);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   PUT api/admin/users/:id/toggle-access
// @desc    Activate/Deactivate user
// @access  Private (Admin)
router.put('/users/:id/toggle-access', auth, authorize('admin'), async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ msg: 'User not found' });
        }

        user.isActive = !user.isActive;
        await user.save();

        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   GET api/admin/audit-logs
// @desc    Get system audit logs
// @access  Private (Admin)
router.get('/audit-logs', auth, authorize('admin'), async (req, res) => {
    try {
        const logs = await AuditLog.find()
            .populate('userId', ['name', 'role'])
            .sort({ timestamp: -1 })
            .limit(100);
        res.json(logs);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   PUT api/admin/doctors/:id/approve
// @desc    Approve a doctor's profile
// @access  Private (Admin)
router.put('/doctors/:id/approve', auth, authorize('admin'), async (req, res) => {
    try {
        const doctor = await Doctor.findOne({ userId: req.params.id });
        if (!doctor) {
            return res.status(404).json({ msg: 'Doctor profile not found' });
        }

        doctor.approvedByAdmin = true;
        await doctor.save();

        // Also ensure user access is active
        await User.findByIdAndUpdate(req.params.id, { isActive: true });

        res.json(doctor);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

module.exports = router;
