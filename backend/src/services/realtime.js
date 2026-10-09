const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');

let io;

function initializeRealtime(server) {
  io = new Server(server, {
    cors: { origin: true, credentials: true },
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth && socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Token autentikasi diperlukan'));
    }

    try {
      socket.user = jwt.verify(token, process.env.JWT_SECRET);
      next();
    } catch (_) {
      next(new Error('Token tidak valid atau kedaluwarsa'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(`user:${socket.user.id}`);
  });
}

function emitToUser(userId, event, payload) {
  if (io) {
    io.to(`user:${userId}`).emit(event, payload);
  }
}

module.exports = { initializeRealtime, emitToUser };
