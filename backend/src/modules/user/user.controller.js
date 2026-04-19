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

  const validRoles = ['owner', 'developer', 'staff', 'vanguard', 'ace_tester', 'user'];
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

  // Check authority for sensitive role assignments (Staff/Admin/Tester cannot promote to Owner/Dev/Staff)
  if (req.user.role === 'staff' || req.user.role === 'admin' || req.user.role === 'ace_tester') {
    const sensitiveRoles = ['owner', 'developer', 'staff', 'admin']; 
    if (sensitiveRoles.includes(role)) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak. Perubahan role administratif hanya dapat dilakukan oleh Owner atau Developer.',
      });
    }
  }

  // Prevent modifying owners/developers/staff unless you have superior authority (Owner/Dev)
  if ((userToUpdate.role === 'owner' || userToUpdate.role === 'developer' || userToUpdate.role === 'staff' || userToUpdate.role === 'admin')) {
    // Non-Top-Tier (Staff/Admin/Tester) cannot modify Staff/Admin/Owner/Developer
    if (req.user.role !== 'owner' && req.user.role !== 'developer') {
         return res.status(403).json({
            success: false,
            message: 'Anda tidak memiliki otoritas untuk mengubah status Staff atau Owner.',
          });
    }

    // Owner/Dev protection
    if ((userToUpdate.role === 'owner' || userToUpdate.role === 'developer')) {
        // Redundant check but good for clarity: if they got here they are Owner/Dev.
        // But Dev can modify Owner. Owner CANNOT modify Dev.
        if (req.user.role === 'owner' && userToUpdate.role === 'developer' && req.user._id.toString() !== userToUpdate._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Owner tidak diizinkan mengubah status Developer.',
            });
        }
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
