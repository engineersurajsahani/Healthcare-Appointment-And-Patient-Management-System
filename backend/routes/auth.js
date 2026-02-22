const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { check, validationResult } = require('express-validator');
const User = require('../models/User');
const Patient = require('../models/Patient');
const Doctor = require('../models/Doctor');
const Admin = require('../models/Admin');

// @route   POST api/auth/register
// @desc    Register user (and Create Profile)
// @access  Public
router.post(
    '/register',
    [
        check('name', 'Name is required').not().isEmpty(),
        check('email', 'Please include a valid email').isEmail(),
        check('password', 'Please enter a password with 6 or more characters').isLength({ min: 6 }),
        check('role', 'Role is required').not().isEmpty(),
        check('phone', 'Phone number is required').not().isEmpty()
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { name, email, password, role, phone } = req.body;

        try {
            // Check if user exists
            let user = await User.findOne({ email });

            if (user) {
                return res.status(400).json({ msg: 'User already exists' });
            }

            user = new User({
                name,
                email,
                password,
                role,
                phone
            });

            // Encrypt password
            const salt = await bcrypt.genSalt(10);
            user.password = await bcrypt.hash(password, salt);

            await user.save();

            // --- CREATE ROLE SPECIFIC PROFILE ---
            if (role === 'patient') {
                const patient = new Patient({
                    userId: user.id,
                    // Add default empty values or handle via profile update later
                    gender: 'Other',
                });
                await patient.save();
            } else if (role === 'doctor') {
                const doctor = new Doctor({
                    userId: user.id,
                    specialization: 'General Physician', // Default
                    availability: []
                });
                await doctor.save();
            } else if (role === 'admin') {
                const admin = new Admin({
                    userId: user.id,
                    department: 'Operations',
                    permissions: ['MANAGE_USERS', 'VIEW_APPOINTMENTS', 'VIEW_AUDIT_LOGS']
                });
                await admin.save();
            }

            // Return jsonwebtoken
            const payload = {
                user: {
                    id: user.id,
                    role: user.role
                }
            };

            jwt.sign(
                payload,
                process.env.JWT_SECRET,
                { expiresIn: '5d' },
                (err, token) => {
                    if (err) throw err;
                    res.json({ token, role: user.role, userId: user.id, name: user.name });
                }
            );
        } catch (err) {
            console.error('Registration Error:', err.message);
            res.status(500).send('Server error: ' + err.message);
        }
    }
);

// @route   POST api/auth/login
// @desc    Authenticate user & get token
// @access  Public
router.post(
    '/login',
    [
        check('email', 'Please include a valid email').isEmail(),
        check('password', 'Password is required').exists()
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { email, password } = req.body;

        try {
            // See if user exists
            let user = await User.findOne({ email });

            if (!user) {
                return res.status(400).json({ msg: 'Invalid Credentials' });
            }

            // Match password
            const isMatch = await bcrypt.compare(password, user.password);

            if (!isMatch) {
                return res.status(400).json({ msg: 'Invalid Credentials' });
            }

            // Return jsonwebtoken
            const payload = {
                user: {
                    id: user.id,
                    role: user.role
                }
            };

            jwt.sign(
                payload,
                process.env.JWT_SECRET,
                { expiresIn: '5d' },
                (err, token) => {
                    if (err) throw err;
                    res.json({ token, role: user.role, userId: user.id, name: user.name });
                }
            );
        } catch (err) {
            console.error(err.message);
            res.status(500).send('Server error');
        }
    }
);

// @route   PUT api/auth/profile
// @desc    Update user profile (image, phone)
// @access  Private
router.put('/profile', require('../middleware/auth').auth, async (req, res) => {
    try {
        const { profileImage, phone } = req.body;
        const user = await User.findById(req.user.id);

        if (profileImage) user.profileImage = profileImage;
        if (phone) user.phone = phone;

        await user.save();
        res.json(user);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

module.exports = router;
