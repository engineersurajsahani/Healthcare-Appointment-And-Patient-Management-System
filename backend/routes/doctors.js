const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const User = require('../models/User');
const Doctor = require('../models/Doctor');

// @route   GET api/doctors
// @desc    Get all doctors (Public/Protected)
// @access  Public (or Private)
router.get('/', auth, async (req, res) => {
    try {
        const doctors = await Doctor.find().populate('userId', ['name', 'email']);

        const result = doctors.map(doc => ({
            _id: doc.userId._id, // User ID for booking
            name: doc.userId.name,
            email: doc.userId.email,
            specialization: doc.specialization,
            experience: doc.experience,
            availability: doc.availability
        }));

        res.json(result);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   PUT api/doctors/availability
// @desc    Update doctor availability
// @access  Private (Doctor)
router.put('/availability', auth, async (req, res) => {
    if (req.user.role !== 'doctor') {
        return res.status(403).json({ msg: 'Not authorized' });
    }

    const { availability } = req.body;

    try {
        let doctor = await Doctor.findOne({ userId: req.user.id });

        if (!doctor) {
            return res.status(404).json({ msg: 'Doctor profile not found' });
        }

        doctor.availability = availability;
        await doctor.save();

        res.json(doctor);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   GET api/doctors/profile
// @desc    Get current doctor profile
// @access  Private (Doctor)
router.get('/profile', auth, async (req, res) => {
    try {
        const doctor = await Doctor.findOne({ userId: req.user.id }).populate('userId', ['name', 'email']);
        if (!doctor) return res.status(404).json({ msg: 'Profile not found' });
        res.json(doctor);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

module.exports = router;
