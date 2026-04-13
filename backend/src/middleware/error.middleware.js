module.exports = function errorHandler(err, req, res, next) {
  let status = err.statusCode || 500;
  let message = err.message || 'Internal server error';

  if (err && err.code === 11000) {
    status = 409;
    const duplicateField = Object.keys(err.keyPattern || {})[0];
    if (duplicateField === 'email') {
      message = 'Email sudah terdaftar';
    } else if (duplicateField === 'username') {
      message = 'Username sudah digunakan';
    } else {
      message = 'Data duplikat terdeteksi';
    }
  }

  if (err && err.name === 'ValidationError') {
    status = 400;
    message = err.message || 'Validasi data gagal';
  }

  if (process.env.NODE_ENV !== 'production') {
    // eslint-disable-next-line no-console
    console.error(err);
  }

  res.status(status).json({
    success: false,
    message,
    data: null,
  });
};
