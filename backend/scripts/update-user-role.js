const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const User = require('../src/modules/auth/user.model');

const updateRole = async () => {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.log('Usage: node update-user-role.js <username> <role>');
        console.log('Roles: owner, developer, staff, user');
        process.exit(1);
    }

    const [username, role] = args;
    const validRoles = ['owner', 'developer', 'staff', 'user'];

    if (!validRoles.includes(role)) {
        console.error(`Error: Invalid role "${role}". Valid roles are: ${validRoles.join(', ')}`);
        process.exit(1);
    }

    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB...');

        const user = await User.findOneAndUpdate(
            { username: username.toLowerCase().trim() },
            { role: role },
            { new: true }
        );

        if (!user) {
            console.error(`Error: User with username "${username}" not found.`);
        } else {
            console.log(`Success! User "${user.username}" updated to role: ${user.role}`);
        }
    } catch (err) {
        console.error('Connection error:', err.message);
    } finally {
        await mongoose.connection.close();
        process.exit(0);
    }
};

updateRole();
