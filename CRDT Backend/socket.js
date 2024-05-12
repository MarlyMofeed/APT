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
  // Get the user from the procided token to fill the userSocketMap.

  // Extract the token from the query parameter.
  //const token = socket.handshake.query.token.split(" ")[1];

  // Verify the token.
  //let user_token;

  //   try {
  //     user_token = jwt.verify(token, process.env.JWT_SECRET);
  //   } catch (err) {
  //     console.log({
  //       err: { status: 401, message: `Invalid Token: ${err.message}` },
  //     });
  //     return; // need to check this
  //   }

  //   const user_id = user_token.user.id;
  //   const user = await User.findById(user_id);

  //   if (!user) {
  //     console.log({ err: { status: 404, message: "User not found" } });
  //   } else {
  //     userSocketMap[user_id] = socket.id;
  //     console.log(userSocketMap);
  //   }

  // socket.on() is used to listen to the events. can be used both on client and server side
  socket.on("disconnect", () => {
    console.log("user disconnected", socket.id);
    // delete userSocketMap[user_id];
  });
});

module.exports = { app, io, server, getReceiverSocketId };
