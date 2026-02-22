const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const MedicalRecord = require('../models/MedicalRecord');
const Appointment = require('../models/Appointment');
const AuditLog = require('../models/AuditLog');
const Patient = require('../models/Patient');

// Helper for "Encryption" (Simulated with Base64 for demo)
const encrypt = (text) => Buffer.from(text).toString('base64');
const decrypt = (text) => Buffer.from(text, 'base64').toString('ascii');

// @route   POST api/medical-records
// @desc    Add a medical record (Consultation details)
// @access  Private (Doctor)
router.post('/', auth, async (req, res) => {
    const { appointmentId, diagnosis, prescription, notes } = req.body;

    try {
        // Fetch appointment to verify ownership and get IDs
        const appointment = await Appointment.findById(appointmentId);
        if (!appointment) {
            return res.status(404).json({ msg: 'Appointment not found' });
        }

        if (appointment.doctorId.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        const newRecord = new MedicalRecord({
            patientId: appointment.patientId,
            doctorId: req.user.id,
            appointmentId: appointmentId,
            diagnosis: diagnosis,
            prescription: prescription,
            notes: notes
        });

        const record = await newRecord.save();

        // Auto-complete the appointment if record is added
        appointment.status = 'Completed';
        await appointment.save();

        // Audit Log
        const audit = new AuditLog({
            userId: req.user.id,
            action: 'CREATE_MEDICAL_RECORD',
            targetId: appointment.patientId,
            ipAddress: req.ip
        });
        await audit.save();

        res.json(record);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   GET api/medical-records/my-records
// @desc    Get medical history (Patient)
// @access  Private (Patient)
router.get('/my-records', auth, async (req, res) => {
    try {
        const records = await MedicalRecord.find({ patientId: req.user.id })
            .populate('doctorId', ['name', 'specialization'])
            .populate('appointmentId', ['date'])
            .sort({ createdAt: -1 });

        // Return records directly (No decryption needed as we stopped encrypting)
        // If older records are encrypted, they will show as Base64. 
        // If older records were plain text (which caused the bug), they will now show correctly.
        res.json(records);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   GET api/medical-records/documents
// @desc    Get uploaded documents (Patient)
// @access  Private (Patient)
router.get('/documents', auth, async (req, res) => {
    try {
        const patient = await Patient.findOne({ userId: req.user.id });
        if (!patient) {
            return res.json([]); // Return empty list if no profile/docs
        }
        res.json(patient.documents);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// @route   POST api/medical-records/upload
// @desc    Upload a document (Patient)
// @access  Private (Patient)
router.post('/upload', auth, async (req, res) => {
    console.log('Document Upload Request:', req.body, 'User:', req.user.id);
    try {
        const { title, url } = req.body;
        let patient = await Patient.findOne({ userId: req.user.id });

        if (!patient) {
            console.log('Patient profile missing for user:', req.user.id, '- Creating new profile...');
            // Auto-create patient profile if missing (Lazy migration)
            patient = new Patient({
                userId: req.user.id,
                gender: 'Other', // Default
                documents: []
            });
            // We don't save yet, we flow down to adding the document
        }

        patient.documents.unshift({ title, url });
        await patient.save();

        console.log('Document metadata saved successfully');
        res.json(patient.documents);
    } catch (err) {
        console.error('Document Upload Error:', err.message);
        res.status(500).send('Server error');
    }
});

// @route   DELETE api/medical-records/documents/:id
// @desc    Delete a document (Patient)
// @access  Private (Patient)
router.delete('/documents/:id', auth, async (req, res) => {
    try {
        const patient = await Patient.findOne({ userId: req.user.id });
        if (!patient) {
            return res.status(404).json({ msg: 'Patient profile not found' });
        }

        // Filter out the document with the given ID
        const docId = req.params.id;

        console.log('Delete Request. DocID:', docId);
        // console.log('Current Documents:', patient.documents); // Use if needed

        // Find if doc exists
        // Use loose equality or .toString() for ObjectId comparison
        const doc = patient.documents.find(d => d._id.toString() === docId);

        if (!doc) {
            console.log('Document not found with ID:', docId);
            return res.status(404).json({ msg: 'Document not found' });
        }

        // Remove it
        patient.documents.pull({ _id: docId });
        await patient.save();

        res.json(patient.documents);
    } catch (err) {
        console.error('Delete Document Error:', err.message);
        res.status(500).send('Server error');
    }
});

module.exports = router;
