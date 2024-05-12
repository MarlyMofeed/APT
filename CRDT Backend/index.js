const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cookieParser = require("cookie-parser");
const cors = require("cors");
const { app, server } = require("./socket.js");
//const app = express();

const PORT = 5000;

app.use(cors());
app.use(bodyParser.json());
app.use(cookieParser());
mongoose
  .connect("mongodb+srv://aptproject:123456!@apt.igjohof.mongodb.net/")
  .then((result) => {
    console.log("Connected to the database");
    server.listen(PORT, (req, res, next) => {
      console.log(`Server running on port ${PORT}`);
      //const userRoutes = require("./routes/userRoutes");

      //app.use("/user", userRoutes);

      app.get("/", function (req, res) {
        res.send("Hello World!");
      });
    });
  })
  .catch((err) => console.log(err));
