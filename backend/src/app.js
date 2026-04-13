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
const allowedOrigins = process.env.CLIENT_URL
  ? process.env.CLIENT_URL.split(',').map((item) => item.trim()).filter(Boolean)
  : '*';

app.use(helmet());
app.use(cors({ origin: allowedOrigins, credentials: allowedOrigins === '*' ? false : true }));
app.use(morgan('dev'));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

app.use('/uploads', express.static(path.resolve(__dirname, '..', 'uploads')));

app.get('/health', (_, res) => {
  res.status(200).json({ success: true, message: 'SmartLife API healthy' });
});

app.post('/login', authController.login);
app.use('/auth', authRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/upload', uploadRoutes);

app.use((_, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use(errorHandler);

module.exports = app;
