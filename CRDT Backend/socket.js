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
const socketUser = {}; //{socketId: userId}
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
  console.log(socket.handshake.query.documentId);
  console.log(document_id);
  const documentToAdd = await Document.findById(document_id);
  console.log("Document to add: ", documentToAdd);
  if (!crdtMap[documentToAdd._id]) {
    if (documentToAdd.crdt.length > 0) {
      // console.log("el document el da5el Document CRDT: ", documentToAdd.crdt);
      // crdtMap[documentToAdd._id] = documentToAdd.crdt;
      crdtMap[documentToAdd._id] = new CRDT();
      crdtMap[documentToAdd._id].struct = documentToAdd.crdt;
    } else {
      console.log("Ana hena ya gama3a");
      crdtMap[documentToAdd._id] = new CRDT();
      console.log("Documentttttttttt CRDT: ", crdtMap);
    }
  } else {
  }
  userDocumentMap.set(user_id, document_id);
  socketUser[socket.id] = user_id;
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
  socket.join(document_id);
  console.log("user joined room: ", document_id);

  // userSocketMap[user_id] = socket.id;
  console.log("User Socket MAP", userSocketMap);
  console.log("User Document MAP", userDocumentMap);
  console.log("Socket User MAP", socketUser);
  console.log("CRDT MAP: ", crdtMap);

  ////////////////////////////////////////////////////////////////////////////////
  /////////////////////////LOCAL Insert///////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  socket.on("localInsert", (character) => {
    console.log("Received local insert operation: ", character);
    if (crdtMap[document_id]) {
      console.log("bada5al fi dah: ", crdtMap[document_id]);
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

  ////////////////////////////////////////////////////////////////////////////////
  /////////////////////////LOCAL DELETE///////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
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

  ////////////////////////////////////////////////////////////////////////////////
  /////////////////////////LOCAL FORMAT///////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  socket.on(
    "localFormatting",
    (character) => {
      console.log("Received local format operation: ");
      console.log("Identifiers: ", character);
      // for (let character of identifiers) {
      // console.log("Character To Format: ", character);
      // if (crdtMap[document_id]) {
      const index = crdtMap[document_id].struct.findIndex(
        (char) => char.digit === character.digit
      );
      crdtMap[document_id].struct[index].bold = character.bold;
      crdtMap[document_id].struct[index].italic = character.italic;
      socket.in(document_id).emit("remoteFormatting", character);

      // }
    }
    // }
  );
  socket.on("disconnect", async () => {
    socket.leave(document_id);

    // if (
    //   userSocketMap.has(document_id) &&
    //   userSocketMap.get(document_id).has(user_id)
    // ) {
    //   const oldSocketId = userSocketMap.get(document_id).get(user_id);
    //   io.sockets.sockets.get(oldSocketId).disconnect();
    // }
    // userSocketMap.get(document_id).set(user_id, socket.id);
    console.log("user disconnected", socket.id);
    // delete userSocketMap[user_id];
    let userId = socketUser[socket.id];
    let documentId = userDocumentMap.get(userId);
    console.log(`User ${userId} disconnected from document ${documentId}`);
    userSocketMap.get(documentId).delete(userId);
    userDocumentMap.delete(userId);
    //remove the respective entry from the socketUser map
    delete socketUser[socket.id];
    if (userSocketMap.get(document_id).size === 0) {
      console.log("No users in the room");
      userSocketMap.delete(document_id);
      const document = await Document.findById(document_id);
      console.log("Document : ", document);
      if (document) {
        console.log("Dah ely ha7oto: ", crdtMap[document_id]);
        document.crdt = crdtMap[document_id].struct;
        await document.save();
        delete crdtMap[document_id];
        // crdtMap.delete(document_id);
      } else {
        console.log("Document not found");
      }
    }
    // socket.disconnect();
    //remove the respective entry from the socketUser map
    delete socketUser[socket.id];

    console.log("User Socket MAP", userSocketMap);
    console.log("User Document MAP", userDocumentMap);
    console.log("Socket User MAP", socketUser);
    console.log("CRDT MAP: ", crdtMap);
  });
});

module.exports = { app, io, server, getReceiverSocketId };
