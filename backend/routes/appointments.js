const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const Appointment = require('../models/Appointment');
const Notification = require('../models/Notification');
const User = require('../models/User');
const Admin = require('../models/Admin');
const Doctor = require('../models/Doctor'); // Assuming needed later

// @route   POST api/appointments
// @desc    Book an appointment
// @access  Private (Patient)
router.post('/', auth, async (req, res) => {
    const { doctorId, date, timeSlot, reason } = req.body;

    try {
        const appointment = new Appointment({
            patientId: req.user.id,
            doctorId,
            date,
            timeSlot,
            reason,
            status: 'Pending'
        });

        await appointment.save();

        // --- NOTIFICATION LOGIC ---

        // 1. Determine severity based on reason keywords
        let urgencyType = 'info'; // Default (Yellow)
        const reasonLower = reason.toLowerCase();

        if (reasonLower.includes('pain') || reasonLower.includes('emergency') || reasonLower.includes('severe') || reasonLower.includes('bleeding') || reasonLower.includes('heart')) {
            urgencyType = 'critical'; // Red
        } else if (reasonLower.includes('fever') || reasonLower.includes('flu') || reasonLower.includes('cough') || reasonLower.includes('infection') || reasonLower.includes('cold')) {
            urgencyType = 'warning'; // Orange
        }

        // 2. Notify Doctor (doctorId is the User ID in our schema)
        const docUser = await User.findById(doctorId);
        await new Notification({
            userId: doctorId,
            message: `New Appointment Request: ${reason} (${date} at ${timeSlot})`,
            type: urgencyType
        }).save();

        // 3. Notify Patient
        await new Notification({
            userId: req.user.id,
            message: `Request sent to Dr. ${docUser ? docUser.name : 'Unknown'} for ${date}. Status: Pending.`,
            type: 'info'
        }).save();

        // 4. Notify ALL Admins
        const admins = await User.find({ role: 'admin' });
        for (const admin of admins) {
            await new Notification({
                userId: admin._id,
                message: `System Alert: New Appointment booked by ${req.user.name} with Dr. ${docUser ? docUser.name : 'Unknown'}.`,
                type: 'info'
            }).save();
        }

        res.json(appointment);
    } catch (err) {
        console.error('Book Error:', err.message);
        res.status(500).send('Server error');
    }
});

// @route   GET api/appointments
// @desc    Get all appointments for the logged-in user
// @access  Private
router.get('/', auth, async (req, res) => {
    try {
        let appointments;
        if (req.user.role === 'doctor') {
            appointments = await Appointment.find({ doctorId: req.user.id })
                .populate('patientId', ['name', 'email', 'phone'])
                .sort({ date: 1 }); // Ascending order for doctor to see nearest first
        } else {
            appointments = await Appointment.find({ patientId: req.user.id })
                .populate('doctorId', ['name', 'specialization'])
                .sort({ date: -1 }); // Descending for patient (history)
        }
        res.json(appointments);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   PUT api/appointments/:id/status
// @desc    Update appointment status (Doctor/Admin)
router.put('/:id/status', auth, async (req, res) => {
    try {
        const { status } = req.body;

        // Find appointment
        let appointment = await Appointment.findById(req.params.id);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        // Verify ownership (Doctor can only update their own, Admin can update any)
        if (req.user.role === 'doctor' && appointment.doctorId.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        appointment.status = status;
        await appointment.save();

        // Notify Patient
        const patientId = appointment.patientId;
        const msg = `Your appointment status has been updated to: ${status}`;

        await new Notification({
            userId: patientId,
            message: msg,
            type: status === 'Approved' ? 'info' : 'warning'
        }).save();

        res.json(appointment);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   POST api/appointments/:id/remind
// @desc    Send a reminder for an appointment
// @access  Private
router.post('/:id/remind', auth, async (req, res) => {
    try {
        const appointment = await Appointment.findById(req.params.id);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        let targetId;
        let message;

        // If Doctor is sending -> Remind Patient
        if (req.user.role === 'doctor' && appointment.doctorId.toString() === req.user.id) {
            targetId = appointment.patientId;
            message = `Reminder: You have an appointment with Dr. ${req.user.name} on ${new Date(appointment.date).toDateString()} at ${appointment.timeSlot}.`;
        }
        // If Patient is sending -> Remind Doctor
        else if (req.user.role === 'patient' && appointment.patientId.toString() === req.user.id) {
            targetId = appointment.doctorId;
            message = `Reminder: Patient ${req.user.name} has an upcoming appointment on ${new Date(appointment.date).toDateString()} at ${appointment.timeSlot}.`;
        } else {
            return res.status(401).json({ msg: 'Not authorized to remind for this appointment' });
        }

        // Create Notification
        await new Notification({
            userId: targetId,
            message: message,
            type: 'info'
        }).save();

        appointment.reminded = true;
        await appointment.save();

        res.json({ msg: 'Reminder sent successfully' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

module.exports = router;
