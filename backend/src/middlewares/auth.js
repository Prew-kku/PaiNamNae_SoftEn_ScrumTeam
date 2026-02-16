const asyncHandler = require('express-async-handler');
const ApiError = require('../utils/ApiError');
const { verifyToken } = require('../utils/jwt');
// Thongchai595-6
const prisma = require('../utils/prisma');
const { text } = require('express');

const protect = asyncHandler(async (req, res, next) => {
    let token;
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer')) {
        try {
            // Get token from header
            token = authHeader.split(' ')[1];

            // Verify token
            const decoded = verifyToken(token);

            // Attach user to the request object
            req.user = {
                sub: decoded.sub,
                role: decoded.role,
            };

            next();
        } catch (error) {
            console.error(error);
            throw new ApiError(401, 'Not authorized, token failed');
        }
    }

    if (!token) {
        throw new ApiError(401, 'Not authorized, no token');
    }

    //Thongchai595-6
    try {
        const decoded = verifyToken(token);

        const user = await prisma.user.findUnique({
            where: { id: decoded.sub },
            select: {
                id: true,
                role: true,
                isActive: true,
                deletedAt: true,
            },
        });

        if (!user){
            throw new ApiError(401, 'User not found');
        }

        // Check Soft Delete
        if (!user.isActive || user.deletedAt){
            throw new ApiError(403, 'Account is deactivated or deleted');
        }

        req.user = user;

        next();
    } catch (error) {
        console.error(error);
        throw new ApiError(401, 'Not authorized, token failed');
    }
}); 

const requireAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'ADMIN') {
        next();
    } else {
        throw new ApiError(403, 'Forbidden: Admin access required');
    }
};

module.exports = { protect, requireAdmin };