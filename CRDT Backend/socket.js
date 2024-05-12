const Server = require("socket.io").Server;
const http = require("http");
const express = require("express");

const app = express();

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
  },
});

const getReceiverSocketId = (receiverId) => {
  return userSocketMap[receiverId];
};

const userSocketMap = {}; // {user_id: socketId}

io.on("connection", async (socket) => {
  console.log("a user connected", socket.id);
  const user_id = socket.handshake.query.id;
  console.log("ANA FL SOCKETS");
  console.log(user_id);

  userSocketMap[user_id] = socket.id;
  console.log(userSocketMap);

  socket.on("message", (message) => {
    console.log("Received message: " + message);
    // Add more logic here to handle incoming messages
  });

  socket.on("disconnect", () => {
    console.log("user disconnected", socket.id);
    delete userSocketMap[user_id]; // Clean up after user disconnects
  });
});

module.exports = { app, io, server, getReceiverSocketId };