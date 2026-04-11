const asyncHandler = require('../../middleware/asyncHandler');
const authService = require('./auth.service');

const register = asyncHandler(async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ success: false, message: 'name, email and password are required' });
  }

  const data = await authService.register({ name, email, password });
  return res.status(201).json({ success: true, ...data });
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'email and password are required' });
  }

  const data = await authService.login({ email, password });
  return res.status(200).json({ success: true, ...data });
});

const me = asyncHandler(async (req, res) => {
  return res.status(200).json({ success: true, user: req.user });
});

module.exports = {
  register,
  login,
  me,
};
