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
// const getReceiverSocketId = (receiverId) => {
//   return userSocketMap[receiverId];
// };
////////////////////////////////////////////////////////////////////////////////
const checkSpan = (struct) => {
  if (struct[struct.length - 1].digit - struct[struct.length - 2].digit <= 1) {
    struct[struct.length - 1].digit += 200;
  }
};
////////////////////////////////////////////////////////////////////////////////
// const userSocketMap = new Map(); // {user_id: socketId}
const crdtMap = new Map(); // {document_id: crdt}
// const socketUser = {}; //{socketId: userId}
// let userDocumentMap = new Map(); // Maps userId to documentId
// const documentMembersMap = {}; // {document_id: [user_id]}
io.on("connect", async (socket) => {
  // console.log(
  //   "a user connected",
  //   socket.id,
  //   "3al document",
  //   socket.handshake.query.documentId
  // );
  const user_id = socket.handshake.query.id;
  const document_id = socket.handshake.query.documentId;
  console.log(socket.handshake.query.documentId);
  console.log(document_id);

  if (crdtMap.has(document_id)) {
    console.log("Document Already Exists in Memory");
    // console.log("el document el da5el Document CRDT: ", documentToAdd.crdt);
    // crdtMap[documentToAdd._id] = documentToAdd.crdt;
    // crdtMap[document_id._id] = new CRDT();
    // crdtMap[document_id._id].struct = document_id.crdt;
    // else {
    // crdtMap[documentToAdd._id] = new CRDT();
    // }
  } else {
    console.log("Loading Document from Database");
    const documentToAdd = await Document.findById(document_id);
    if (documentToAdd.crdt.length > 0) {
      console.log("el crdt bta3et el document feeha data");
      let crdt = new CRDT();
      crdt.struct = documentToAdd.crdt;
      crdtMap.set(document_id, crdt);
    } else {
      console.log("el crdt bta3et el document fadya");
      let crdt = new CRDT();
      crdtMap.set(document_id, crdt);
    }
  }
  console.log("Document CRDT 5ARA: ", crdtMap);
  console.log("Document CRDT: ", crdtMap.get(document_id));
  console.log("Sending Document to User");
  socket.emit("receiveDocument", crdtMap.get(document_id).struct);
  socket.join(document_id);
  // console.log("user joined room: ", document_id);

  // userSocketMap[user_id] = socket.id;
  // console.log("User Socket MAP", userSocketMap);
  // console.log("User Document MAP", userDocumentMap);
  // console.log("Socket User MAP", socketUser);
  console.log("CRDT MAP: ", crdtMap);

  ////////////////////////////////////////////////////////////////////////////////
  /////////////////////////LOCAL Insert///////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  socket.on("localInsert", (character) => {
    console.log("Received local insert operation: ", character);
    if (crdtMap.get(document_id)) {
      console.log("bada5al fi dah: ", crdtMap.get(document_id));
      crdtMap.get(document_id).struct.push(character);
      console.log("Document CRDT: ", crdtMap.get(document_id));
      crdtMap.get(document_id).struct.sort((a, b) => {
        const digitA = parseInt(a.digit);
        const digitB = parseInt(b.digit);
        return digitA - digitB;
      });
      checkSpan(crdtMap.get(document_id).struct);
      console.log("Document CRDT: ", crdtMap.get(document_id));
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
    if (crdtMap.get(document_id)) {
      const index = crdtMap
        .get(document_id)
        .struct.findIndex((char) => char.digit === character.digit);
      crdtMap.get(document_id).struct.splice(index, 1);
      console.log("Document CRDT After DELETE: ", crdtMap.get(document_id));
    }
    socket.in(document_id).emit("remoteDelete", character);
  });

  ////////////////////////////////////////////////////////////////////////////////
  /////////////////////////LOCAL FORMAT///////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////
  socket.on("localFormatting", (data) => {
    console.log("Received local format operation: ");
    const identifiers = data.identifiers;
    console.log("Identifiers: ", identifiers);
    const formattedCharacters = [];
    for (let character of identifiers) {
      console.log("Character To Format: ", character);
      console.log("Document CRDT: ", crdtMap.get(document_id));

      if (crdtMap.get(document_id)) {
        const index = crdtMap
          .get(document_id)
          .struct.findIndex((char) => char.digit === character.digit);

        console.log("Index: ", index);
        crdtMap.get(document_id).struct[index].bold = character.bold;
        crdtMap.get(document_id).struct[index].italic = character.italic;
        console.log("Character: ", crdtMap.get(document_id).struct[index]);
        formattedCharacters.push(crdtMap.get(document_id).struct[index]);
      }
    }
    console.log(formattedCharacters);
    socket.in(document_id).emit("remoteFormatting", formattedCharacters);
  });
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
    // let userId = socketUser[socket.id];
    // let documentId = userDocumentMap.get(userId);
    // console.log(User ${userId} disconnected from document ${documentId});
    // userSocketMap.get(documentId).delete(userId);
    // userDocumentMap.delete(userId);
    //remove the respective entry from the socketUser map
    // delete socketUser[socket.id];
    if (io.sockets.adapter.rooms[document_id] === 0) {
      console.log("No users in the room");
      // userSocketMap.delete(document_id);
      const document = await Document.findById(document_id);
      console.log("Document : ", document);
      if (document) {
        console.log("Dah ely ha7oto: ", crdtMap.get(document_id));
        document.crdt = crdtMap.get(document_id).struct;
        await document.save();
        delete crdtMap.get(document_id);
        // crdtMap.delete(document_id);
      } else {
        console.log("Document not found");
      }
    }
    // socket.disconnect();
    //remove the respective entry from the socketUser map
    // delete socketUser[socket.id];

    // console.log("User Socket MAP", userSocketMap);
    // console.log("User Document MAP", userDocumentMap);
    // console.log("Socket User MAP", socketUser);
    console.log("CRDT MAP: ", crdtMap);
  });
});

module.exports = { app, io, server };
