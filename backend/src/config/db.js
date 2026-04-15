const mongoose = require('mongoose');

async function connectDatabase() {
  const mongoUri = process.env.MONGO_URI;

  if (!mongoUri) {
    throw new Error('MONGO_URI is not defined');
  }

  try {
    mongoose.set('strictQuery', true);
    await mongoose.connect(mongoUri);
    // eslint-disable-next-line no-console
    console.log('MongoDB connected successfully');
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(
      'MongoDB connection error. Pastikan MONGO_URI valid, host Atlas dapat di-resolve, kredensial benar, dan IP kamu sudah diizinkan di Atlas Network Access.'
    );
    throw error;
  }
}

module.exports = connectDatabase;
