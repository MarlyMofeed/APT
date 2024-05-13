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
  const document_id = socket.handshake.query.documentId;
  console.log("ANA FL SOCKETS");
  console.log(user_id);

  userSocketMap[user_id] = socket.id;
  console.log(userSocketMap);
  socket.join(document_id);
  console.log("user joined room: ", document_id);

  socket.on("localInsert", (character) => {
    console.log("Received local insert operation: ", character);
    socket.broadcast.emit("remoteInsert", character);
  });
  socket.on("localDelete", (character) => {
    console.log("Received local delete operation: ", character);
    socket.broadcast.emit("remoteDelete", character);
  });
  socket.on("disconnect", () => {
    console.log("user disconnected", socket.id);
    delete userSocketMap[user_id];
  });
  
});

module.exports = { app, io, server, getReceiverSocketId };
