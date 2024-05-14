const Server = require("socket.io").Server;
const http = require("http");
const express = require("express");
const CRDT = require("./Data Structure/CRDTclass");
const app = express();

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
  },
});
const crdt = new CRDT();
const getReceiverSocketId = (receiverId) => {
  return userSocketMap[receiverId];
};
////////////////////////////////////////////////////////////////////////////////
const checkSpan = (struct) => {
  if (struct[struct.length - 1].digit - struct[struct.length - 2].digit <= 1) {
    struct[struct.length - 1].digit += 200;
  }
};
////////////////////////////////////////////////////////////////////////////////
const userSocketMap = {}; // {user_id: socketId}
const crdtMap = {}; // {document_id: crdt}
io.on("connection", async (socket) => {
  console.log("a user connected", socket.id);
  const user_id = socket.handshake.query.id;
  const document_id = socket.handshake.query.documentId;
  console.log("ANA FL SOCKETS");
  console.log(user_id);
  if (!crdtMap[document_id]) {
    crdtMap[document_id] = new CRDT();
  }
  userSocketMap[user_id] = socket.id;
  console.log("User MAP", userSocketMap);
  console.log("CRDT MAP: ", crdtMap);
  socket.join(document_id);
  console.log("user joined room: ", document_id);

  socket.on("localInsert", (character) => {
    console.log("Received local insert operation: ", character);
    if (crdtMap[document_id]) {
      crdtMap[document_id].struct.push(character);
      console.log("Document CRDT: ", crdtMap[document_id]);
      crdtMap[document_id].struct.sort((a, b) => {
        const digitA = parseInt(a.digit);
        const digitB = parseInt(b.digit);
        return digitA - digitB;
      });
      checkSpan(crdtMap[document_id].struct);
      console.log("Document CRDT: ", crdtMap[document_id]);
    }
    //TODO: LAW el document msh mawgood fel map
    // crdt.localInsert(character.value, character.);
    // socket.broadcast.emit("remoteInsert", character);
    socket.in(document_id).emit("remoteInsert", character);
  });
  socket.on("localDelete", (character) => {
    console.log("Received local delete operation: ", character);
    if (crdtMap[document_id]) {
      const index = crdtMap[document_id].struct.findIndex(
        (char) => char.digit === character.digit
      );
      crdtMap[document_id].struct.splice(index, 1);
      console.log("Document CRDT After DELETE: ", crdtMap[document_id]);
    }
    socket.in(document_id).emit("remoteDelete", character);
  });
  socket.on("disconnect", () => {
    console.log("user disconnected", socket.id);
    delete userSocketMap[user_id];
  });
});

module.exports = { app, io, server, getReceiverSocketId };
