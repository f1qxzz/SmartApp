const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./modules/auth/auth.routes');
const authController = require('./modules/auth/auth.controller');
const chatRoutes = require('./modules/chat/chat.routes');
const financeRoutes = require('./modules/finance/finance.routes');
const aiRoutes = require('./modules/ai/ai.routes');
const uploadRoutes = require('./modules/upload/upload.routes');
const errorHandler = require('./middleware/error.middleware');

const app = express();
const defaultClientOrigins = [
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
  'http://localhost:8080',
  'http://127.0.0.1:8080',
];

const configuredOrigins = String(process.env.CLIENT_URL || '')
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean);

const allowedOrigins = new Set([...defaultClientOrigins, ...configuredOrigins]);
const allowAnyOrigin = configuredOrigins.length === 0 && process.env.NODE_ENV !== 'production';

app.use(helmet());
app.use(
  cors({
    origin(origin, callback) {
      if (!origin) {
        return callback(null, true);
      }

      if (allowAnyOrigin || allowedOrigins.has(origin)) {
        return callback(null, true);
      }

      return callback(new Error('Origin not allowed by CORS'));
    },
    credentials: true,
  })
);
app.use(morgan('dev'));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

app.use('/uploads', express.static(path.resolve(__dirname, '..', 'uploads')));

app.get('/health', (_, res) => {
  res.status(200).json({ success: true, message: 'SmartLife API healthy' });
});

app.post('/login', authController.login);
app.post('/register', authController.register);
app.use('/auth', authRoutes);
app.use('/api/auth', authRoutes);
app.use('/', chatRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/upload', uploadRoutes);

app.use((_, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use(errorHandler);

module.exports = app;
