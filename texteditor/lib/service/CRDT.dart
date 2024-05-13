class Identifier {
  int digit;
  String siteId;

  Identifier(this.digit, this.siteId);

  @override
  String toString() {
    return 'Identifier(digit: $digit, siteId: $siteId)';
  }

  Map<String, dynamic> toJson() {
    return {
      'digit': this.digit,
      'siteId': this.siteId,
    };
  }
}

class CRDT {
  String siteId;
  List<Map<String, dynamic>> struct = [];

  CRDT(this.siteId);

  Map<String, dynamic> generateChar(String val, int index) {
    List<Identifier> posBefore = index > 0 ? struct[index - 1]['position'] : [];
    List<Identifier> posAfter =
        index < struct.length ? struct[index]['position'] : [];
    List<Identifier> newPos = generatePosBetween(posBefore, posAfter);

    return {
      'value': val,
      'position': newPos,
    };
  }

  List<Identifier> generatePosBetween(
      List<Identifier> pos1, List<Identifier> pos2) {
    Identifier id1 = pos1.isNotEmpty ? pos1[0] : Identifier(0, siteId);
    Identifier id2 = pos2.isNotEmpty
        ? pos2[0]
        : Identifier(9007199254740991, siteId); // Number.MAX_SAFE_INTEGER

    if (id2.digit - id1.digit > 1) {
      int newDigit = generateIdBetween(id1.digit, id2.digit);
      return [Identifier(newDigit, siteId)];
    } else if (id2.digit - id1.digit == 1) {
      return generatePosBetween(pos1.sublist(1), pos2);
    }

    return [];
  }

  int generateIdBetween(int digit1, int digit2) {
    return ((digit1 + digit2) / 2).floor();
  }

  Map<String, dynamic> localInsert(String value, int index) {
    Map<String, dynamic> char = generateChar(value, index);
    struct.insert(index, char);
    return char;
  }

  Map<String, dynamic> localDelete(int index) {
    if (index < 0 || index >= struct.length) {
      throw RangeError('index out of range');
    }
    Map<String, dynamic> char = struct.removeAt(index);
    return char;
  }

  Map<String, dynamic> remoteInsert(Map<String, dynamic> char) {
    int index = findInsertIndex(char);
    struct.insert(index, char);
    return {'char': char['value'], 'index': index};
  }

  int remoteDelete(Map<String, dynamic> char) {
    int index = findIndexByPosition(char);
    if (index != -1) {
      struct.removeAt(index);
    }
    return index;
  }

  int findInsertIndex(Map<String, dynamic> char) {
    int low = 0;
    int high = struct.length;

    while (low < high) {
      int mid = ((low + high) / 2).floor();
      Map<String, dynamic> currentChar = struct[mid];

      if (comparePositions(char['position'], currentChar['position']) < 0) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    return low;
  }

  int findIndexByPosition(Map<String, dynamic> char) {
    int low = 0;
    int high = struct.length;

    while (low < high) {
      int mid = ((low + high) / 2).floor();
      Map<String, dynamic> currentChar = struct[mid];

      int comparison =
          comparePositions(char['position'], currentChar['position']);
      if (comparison == 0) {
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

  int comparePositions(List<Identifier> pos1, List<Identifier> pos2) {
    for (int i = 0; i < pos1.length; i++) {
      if (i >= pos2.length) {
        return 1; // pos1 comes after pos2 if it has more identifiers
      }

      if (pos1[i].digit != pos2[i].digit) {
        return pos1[i].digit - pos2[i].digit;
      }

      if (pos1[i].siteId != pos2[i].siteId) {
        return pos1[i].siteId.compareTo(pos2[i].siteId);
      }
    }

    if (pos1.length < pos2.length) {
      return -1; // pos1 comes before pos2 if it has fewer identifiers
    }

    return 0; // pos1 and pos2 are equal
  }
}

// void main() {
//   CRDT crdt = CRDT("site1");
//   crdt.localInsert("A", 0);
//   crdt.localInsert("B", 1);
//   crdt.localInsert("C", 2);
//   crdt.localInsert("D", 0);
//   print(crdt.struct
//       .map((char) => ({
//             'value': char['value'],
//             'position': (char['position'] as List<Identifier>)
//                 .map((id) => id.toString())
//                 .toList()
//           }))
//       .toList());
// }
