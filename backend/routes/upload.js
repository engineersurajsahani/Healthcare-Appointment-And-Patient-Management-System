const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Define storage for files
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadPath = 'uploads/';
        // Create directory if it doesn't exist (though we did it manually)
        if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath);
        }
        cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
        // Unique filename: fieldname-timestamp.ext
        cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
    }
});

// File filter
const fileFilter = (req, file, cb) => {
    console.log('Incoming file:', file.originalname, 'MIME:', file.mimetype);

    // Check file types
    const allowedExtensions = /jpeg|jpg|png|pdf|doc|docx|xlsx|xls/;

    // Check extension
    const extname = allowedExtensions.test(path.extname(file.originalname).toLowerCase());

    // Check mime - Allow generic image/ and application/pdf + specific docs
    const isImage = file.mimetype.startsWith('image/');
    const isPdf = file.mimetype === 'application/pdf';
    const isDoc = file.mimetype === 'application/msword' ||
        file.mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    const isExcel = file.mimetype === 'application/vnd.ms-excel' ||
        file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    // Allow generic binary stream (common upload issue)
    const isGeneric = file.mimetype === 'application/octet-stream';

    if (extname && (isImage || isPdf || isDoc || isExcel || isGeneric)) {
        return cb(null, true);
    } else {
        console.error('File rejected:', file.originalname, file.mimetype);
        cb(new Error('Error: File type not supported! Got: ' + file.mimetype));
    }
};

const upload = multer({
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
    fileFilter: fileFilter
}).single('file');


// @route   POST api/upload
// @desc    Upload a single file
// @access  Public
router.post('/', (req, res) => {
    upload(req, res, (err) => {
        if (err) {
            console.error('Multer Error:', err);
            return res.status(400).json({ msg: err.message });
        }

        if (!req.file) {
            return res.status(400).json({ msg: 'No file uploaded' });
        }

        const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

        res.json({
            msg: 'File uploaded successfully',
            fileName: req.file.filename,
            filePath: fileUrl
        });
    });
});

module.exports = router;
