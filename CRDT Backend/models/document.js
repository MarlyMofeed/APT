const mongoose = require("mongoose");

const DocumentSchema = new mongoose.Schema({
  name: {
    type: String,
    unique: true,
  },
  content: [[String]],
  ownerId: String,
  sharedWith: String,
  version: { type: Number, default: 0 },
  editUserLatestVersion: Map,
  bufferStartVersion: Number,
  changesBuffer: [[String, Number]],
  crdt: [
    {
      value: String,
      digit: Number,
      siteId: String,
      bold: Number,
      italic: Number,
    },
  ],
});

module.exports = mongoose.model("Documents", DocumentSchema);
