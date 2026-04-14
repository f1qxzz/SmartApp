const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const authMiddleware = require('../../middleware/auth.middleware');

// Cloudinary Configuration
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Configure Cloudinary Storage for Multer
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'smartlife',
    resource_type: 'auto', // Automatically detect if image or audio (voice note)
    allowed_formats: ['jpg', 'png', 'jpeg', 'mp3', 'm4a', 'wav'],
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // Increased to 10MB for voice notes
});

const router = express.Router();

router.post('/', authMiddleware, upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'file is required' });
  }

  // Cloudinary returns the full public URL in req.file.path
  return res.status(201).json({ 
    success: true, 
    data: { 
      url: req.file.path,
      originalName: req.file.originalname 
    } 
  });
});

module.exports = router;

