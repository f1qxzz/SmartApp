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
    console.error('MongoDB connection error. Please ensure MongoDB is running locally on port 27017 or provide a valid MONGO_URI in .env');
    throw error;
  }
}

module.exports = connectDatabase;
