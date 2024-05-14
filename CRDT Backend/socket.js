const Server = require("socket.io").Server;
const http = require("http");
const express = require("express");
const CRDT = require("./Data Structure/CRDTclass");
const app = express();
const server = http.createServer(app);
const Document = require("./models/document");

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
const userSocketMap = new Map(); // {user_id: socketId}
const crdtMap = {}; // {document_id: crdt}
let userDocumentMap = new Map(); // Maps userId to documentId
// const documentMembersMap = {}; // {document_id: [user_id]}
io.on("connection", async (socket) => {
  console.log(
    "a user connected",
    socket.id,
    "3al document",
    socket.handshake.query.documentId
  );
  const user_id = socket.handshake.query.id;
  const document_id = socket.handshake.query.documentId;
  console.log("ANA FL SOCKETS");
  console.log(user_id);
  if (!crdtMap[document_id]) {
    crdtMap[document_id] = new CRDT();
  }
  userDocumentMap.set(user_id, document_id);

  // if (!documentMembersMap[document_id]) {
  //   documentMembersMap[document_id] = 1;
  // } else {
  //   documentMembersMap[document_id]++;
  // }
  if (!userSocketMap.has(document_id)) {
    userSocketMap.set(document_id, new Map());
    userSocketMap.get(document_id).set(user_id, socket.id);
  } else {
    userSocketMap.get(document_id).set(user_id, socket.id);
  }

  // userSocketMap[user_id] = socket.id;
  console.log("User MAP", userSocketMap);
  console.log("User Document MAP", userDocumentMap);
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
  socket.on("disconnect", async () => {
    console.log("user disconnected", socket.id);
    // delete userSocketMap[user_id];
    userSocketMap.get(document_id).delete(user_id);
    //TODO: EL 7ETA DEH HATBOOOOZ
    let userId = socketUserMap.get(socket.id);
    let documentId = userDocumentMap.get(userId);

    console.log(`User ${userId} disconnected from document ${documentId}`);
    socketUserMap.delete(socket.id);
    userDocumentMap.delete(userId);
    // if (userSocketMap.get(document_id).size === 0) {
    //   console.log("No users in the room");
    //   let documentId = userSocketMap.get(user_id); // Get the document ID
    //   const document = await Document.findById(document_id);
    //   console.log("Document : ", document);
    //   if (document) {
    //     document.crdt = crdtMap[document_id];
    //     await document.save();
    //   } else {
    //     console.log("Document not found");
    //   }
    // }
  });
});

module.exports = { app, io, server, getReceiverSocketId };
