const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const authMiddleware = require('../../middleware/auth.middleware');
const MAX_UPLOAD_SIZE_BYTES = 20 * 1024 * 1024;

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
    resource_type: 'auto', // Support image + voice note upload
    allowed_formats: [
      'jpg',
      'jpeg',
      'jfif',
      'png',
      'bmp',
      'heic',
      'heif',
      'avif',
      'webp',
      'gif',
      'tif',
      'tiff',
      'mp3',
      'm4a',
      'wav',
      'aac',
      'amr',
      'ogg',
      'webm',
      '3gp',
      'mp4',
    ],
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: MAX_UPLOAD_SIZE_BYTES,
    files: 1,
  },
});

const router = express.Router();

function uploadSingleFile(req, res, next) {
  upload.single('file')(req, res, (error) => {
    if (!error) {
      return next();
    }

    if (error instanceof multer.MulterError) {
      if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({
          success: false,
          message: 'Ukuran file melebihi batas 20MB',
        });
      }

      return res.status(400).json({
        success: false,
        message: `Upload gagal: ${error.message}`,
      });
    }

    return res.status(400).json({
      success: false,
      message: error.message || 'Upload file gagal',
    });
  });
}

router.post('/', authMiddleware, uploadSingleFile, (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'file is required' });
  }

  // Cloudinary stores URL in "path" (and in some versions "secure_url").
  const uploadedUrl = req.file.path || req.file.secure_url || req.file.url || '';
  if (!uploadedUrl) {
    return res.status(500).json({
      success: false,
      message: 'Upload berhasil tapi URL file tidak ditemukan',
    });
  }

  return res.status(201).json({
    success: true,
    data: {
      url: uploadedUrl,
      originalName: req.file.originalname,
    },
  });
});

module.exports = router;

