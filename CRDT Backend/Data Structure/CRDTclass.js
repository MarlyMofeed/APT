// Define Identifier class to represent site IDs and positions
class Identifier {
  constructor(digit, siteId) {
    this.digit = digit;
    this.siteId = siteId;
  }

  toString() {
    return `Identifier(digit: ${this.digit}, siteId: ${this.siteId})`;
  }
}

// Define CRDT class
class CRDT {
  constructor(id) {
    this.siteId = id;
    this.struct = [];
  }

  // Generate globally unique fractional index position for a new character
  generateChar(val, index) {
    const posBefore =
      (this.struct[index - 1] && this.struct[index - 1].position) || [];
    const posAfter = (this.struct[index] && this.struct[index].position) || [];
    const newPos = this.generatePosBetween(posBefore, posAfter);

    return {
      value: val,
      position: newPos,
    };
  }

  // Generate position between two given positions
  generatePosBetween(pos1, pos2, newPos = []) {
    let id1 = pos1[0] || new Identifier(0, this.siteId);
    let id2 = pos2[0] || new Identifier(Number.MAX_SAFE_INTEGER, this.siteId);

    if (id2.digit - id1.digit > 1) {
      let newDigit = this.generateIdBetween(id1.digit, id2.digit);
      newPos.push(new Identifier(newDigit, this.siteId));
      return newPos;
    } else if (id2.digit - id1.digit === 1) {
      newPos.push(id1);
      return this.generatePosBetween(pos1.slice(1), pos2, newPos);
    }
  }
  //   generatePosBetween(pos1, pos2, newPos=[]) {
  //     let id1 = pos1[0];
  //     let id2 = pos2[0];

  //     if (id2.digit - id1.digit > 1) {

  //       let newDigit = this.generateIdBetween(id1.digit, id2.digit);
  //       newPos.push(new Identifier(newDigit, this.siteId));
  //       return newPos;

  //     } else if (id2.digit - id1.digit === 1) {

  //       newPos.push(id1);
  //       return this.generatePosBetween(pos1.slice(1), pos2, newPos);

  //     }
  //   }
  // Generate ID between two given IDs
  generateIdBetween(digit1, digit2) {
    // Generate a unique digit between digit1 and digit2
    return (digit1 + digit2) / 2;
  }
  // Local Insert operation
  localInsert(value, index) {
    const char = this.generateChar(value, index);
    this.struct.splice(index, 0, char);
    return char;
  }

  // Local Delete operation
  localDelete(idx) {
    return this.struct.splice(idx, 1)[0];
  }

  // Remote Insert operation
  remoteInsert(char) {
    const index = this.findInsertIndex(char);
    this.struct.splice(index, 0, char);
    return { char: char.value, index: index };
  }

  // Remote Delete operation
  remoteDelete(char) {
    const index = this.findIndexByPosition(char);
    this.struct.splice(index, 1);
    return index;
  }

  // Find index to insert a character based on its position
  findInsertIndex(char) {
    let low = 0;
    let high = this.struct.length;

    while (low < high) {
      const mid = Math.floor((low + high) / 2);
      const currentChar = this.struct[mid];

      if (this.comparePositions(char.position, currentChar.position) < 0) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    return low;
  }

  // Find index of a character by its position
  findIndexByPosition(char) {
    let low = 0;
    let high = this.struct.length;

    while (low < high) {
      const mid = Math.floor((low + high) / 2);
      const currentChar = this.struct[mid];

      const comparison = this.comparePositions(
        char.position,
        currentChar.position
      );
      if (comparison === 0) {
        return mid;
      } else if (comparison < 0) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // If the character is not found, return -1
    return -1;
  }
  compareChars(char1, char2) {
    for (let i = 0; i < char1.position.length; i++) {
      if (i >= char2.position.length) {
        return 1; // char1 comes after char2 if it has more identifiers
      }

      if (char1.position[i].digit !== char2.position[i].digit) {
        return char1.position[i].digit - char2.position[i].digit;
      }

      if (char1.position[i].siteId !== char2.position[i].siteId) {
        return char1.position[i].siteId.localeCompare(char2.position[i].siteId);
      }
    }

    if (char1.position.length < char2.position.length) {
      return -1; // char1 comes before char2 if it has fewer identifiers
    }

    return 0; // char1 and char2 are equal
  }
}

// Example usage
const crdt = new CRDT("site1");
crdt.localInsert("A", 0);
crdt.localInsert("B", 1);
crdt.localInsert("C", 2);
crdt.localInsert("D", 0);
console.log(
  crdt.struct.map((char) => ({
    value: char.value,
    position: char.position.map((id) => id.toString()),
  }))
);
