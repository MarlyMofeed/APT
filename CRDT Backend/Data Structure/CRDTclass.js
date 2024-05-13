const { v4: uuidv4 } = require("uuid");

class Identifier {
  constructor(value, digit, siteId) {
    this.value = value;
    this.digit = digit;
    this.siteId = siteId;
  }

  toString() {
    return `Identifier(value: ${this.value} ,digit: ${this.digit}, siteId: ${this.siteId})`;
  }

  toJson() {
    return {
      value: this.value,
      digit: this.digit,
      siteId: this.siteId,
    };
  }
}

class CRDT {
  constructor() {
    this.struct = [];
    this.struct.push(new Identifier("\0", -2000, uuidv4()));
    this.struct.push(new Identifier("\0", 2000, uuidv4()));
  }

  generateChar(val, index) {
    let posBefore = index === 0 ? this.struct[0] : this.struct[index];
    let posAfter = index === 0 ? this.struct[1] : this.struct[index + 1];
    let siteId = uuidv4();
    let newPos = this.generatePosBetween(val, posBefore, posAfter, siteId);

    return newPos;
  }

  generatePosBetween(value, pos1, pos2, siteId) {
    let newDigit = this.generateIdBetween(pos1?.digit ?? 0, pos2?.digit ?? 0);
    if (this.struct[this.struct.length - 1].digit - newDigit <= 1) {
      this.struct[this.struct.length - 1].digit += 200;
    }
    return new Identifier(value, newDigit, siteId);
  }

  generateIdBetween(digit1, digit2) {
    return (digit1 + digit2) / 2;
  }

  localInsert(value, index) {
    let char = this.generateChar(value, index);
    this.struct.push(char);
    this.struct.sort((a, b) => a.digit - b.digit);
    return char;
  }

  localDelete(index) {
    if (index < 0 || index >= this.struct.length) {
      throw new RangeError("index out of range");
    }
    let char = this.struct.splice(index, 1)[0];
    return char;
  }

  remoteInsert(char) {
    this.struct.push(char);
    this.struct.sort((a, b) => a.digit - b.digit);
    return char;
  }

  findIndex(struct, target) {
    return struct.findIndex((identifier) => identifier === target);
  }
}

module.exports = CRDT;
