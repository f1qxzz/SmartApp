const asyncHandler = require('../../middleware/asyncHandler');
const User = require('../auth/user.model');

const getAllUsers = asyncHandler(async (req, res) => {
  const users = await User.find({})
    .select('-password -__v')
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    data: users,
  });
});

const updateUserRole = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { role } = req.body;

  const validRoles = ['owner', 'developer', 'staff', 'user'];
  if (!validRoles.includes(role)) {
    return res.status(400).json({
      success: false,
      message: 'Role tidak valid.',
    });
  }

  const userToUpdate = await User.findById(id);
  
  if (!userToUpdate) {
    return res.status(404).json({
      success: false,
      message: 'Pengguna tidak ditemukan.',
    });
  }

  // Prevent modifying other owners unless you are a developer or owner too
  // Actually, 'developer' and 'owner' are highest.
  if ((userToUpdate.role === 'owner' || userToUpdate.role === 'developer') && req.user._id.toString() !== userToUpdate._id.toString()) {
    // Only developer can modify owner, or owner can modify owner (we just allow both if they got this far, but usually owner is highest tier).
    if (req.user.role !== 'owner' && req.user.role !== 'developer') {
        return res.status(403).json({
            success: false,
            message: 'Anda tidak memiliki otoritas mengubah status owner/developer.',
          });
    }
  }

  userToUpdate.role = role;
  await userToUpdate.save();

  res.status(200).json({
    success: true,
    message: 'Role pengguna berhasil diperbarui.',
    data: {
      _id: userToUpdate._id,
      username: userToUpdate.username,
      name: userToUpdate.name,
      role: userToUpdate.role,
    },
  });
});

module.exports = {
  getAllUsers,
  updateUserRole,
};
