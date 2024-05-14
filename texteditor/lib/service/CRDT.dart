import 'package:uuid/uuid.dart';

class Identifier {
  String value;
  double digit;
  String siteId;
  int bold = 0;
  int italic = 0;

  Identifier(this.value, this.digit, this.siteId, this.bold, this.italic);

  @override
  String toString() {
    return 'Identifier(value: $value ,digit: $digit, siteId: $siteId , bold: $bold, italic: $italic)';
  }

  Map<String, dynamic> toJson() {
    return {
      'value': this.value,
      'digit': this.digit,
      'siteId': this.siteId,
      'bold': this.bold,
      'italic': this.italic,
    };
  }
}

class CRDT {
  // String siteId;
  List<Identifier> struct = [];

  CRDT() {
    struct.add(Identifier('\0', -2000, Uuid().v4(), 0, 0));
    struct.add(Identifier('\0', 2000, Uuid().v4(), 0, 0));
  }

  Identifier generateChar(String val, int index, int bold, int italic) {
    print("ANA HENAAA");
    print("INDEX: $index");
    Identifier? posBefore = index == 0 ? struct[0] : struct[index];
    Identifier? posAfter = index == 0 ? struct[1] : struct[index + 1];
    print("POS BEFORE: $posBefore");
    print("POS AFTER: $posAfter");
    var siteId = Uuid().v4();
    Identifier newPos =
        generatePosBetween(val, posBefore, posAfter, siteId, bold, italic);

    return newPos;
  }

  Identifier generatePosBetween(String value, Identifier? pos1,
      Identifier? pos2, String siteId, int bold, int italic) {
    // Identifier id1 = pos1.isNotEmpty ? pos1[0] : Identifier(0, siteId);
    // Identifier id2 = pos2.isNotEmpty
    // ? pos2[0]
    // : Identifier(9007199254740991, siteId); // Number.MAX_SAFE_INTEGER

    // if (pos2.digit - pos1.digit > 1) {
    print(pos1?.digit);
    print(pos2?.digit);
    double newDigit = generateIdBetween(pos1?.digit ?? 0, pos2?.digit ?? 0);
    if (struct.last.digit - newDigit <= 1) {
      struct.last.digit += 200;
    }
    return Identifier(value, newDigit, siteId, bold, italic);
    // }
    // else if (pos2.digit - pos1.digit == 1) {
    //   return generatePosBetween(pos1.sublist(1), pos2, siteId);
    // }

    // return [];
  }

  double generateIdBetween(double digit1, double digit2) {
    print(digit1);
    print(digit2);
    return (digit1 + digit2) / 2;
  }

  Identifier localInsert(String value, int index, int bold, int italic) {
    Identifier char = generateChar(value, index, bold, italic);
    // struct.insert(index, char);
    struct.add(char);
    struct.sort((a, b) => a.digit.compareTo(b.digit));
    print("ANA EL STRUCT");
    print(struct);
    return char;
  }

  Identifier localDelete(int index) {
    // if (index < 0 || index >= struct.length) {
    //   throw RangeError('index out of range');
    // }
    // Identifier char = struct.removeAt(index);
    // return char;
    Identifier charToRemove = struct[index];
    print("Gowa el delete: $charToRemove");
    struct.remove(charToRemove);
    return charToRemove;
  }

  Identifier remoteInsert(Identifier char) {
    struct.add(char);
    struct.sort((a, b) => a.digit.compareTo(b.digit));
    return char;
  }

  int findIndex(List<Identifier> struct, Identifier target) {
    return struct.indexWhere((identifier) => identifier == target);
  }

  // Identifier remoteDelete(Identifier char) {
  //   int index = findIndexByPosition(char);
  //   if (index != -1) {
  //     struct.removeAt(index);
  //   }
  //   return char;
  // }
  int remoteDelete(Identifier char) {
    int index = findIndexByPosition(char);
    if (index != -1) {
      struct.removeAt(index);
    }
    return index;
  }
  // int findInsertIndex(Map<String, dynamic> char) {
  //   int low = 0;
  //   int high = struct.length;

  //   while (low < high) {
  //     int mid = ((low + high) / 2).floor();
  //     Map<String, dynamic> currentChar = struct[mid];

  //     if (comparePositions(char['position'], currentChar['position']) < 0) {
  //       high = mid;
  //     } else {
  //       low = mid + 1;
  //     }
  //   }

  //   return low;
  // }

  int findIndexByPosition(Identifier char) {
    if (struct.isEmpty) {
      return -1;
    }
    int index =
        struct.indexWhere((identifier) => identifier.digit == char.digit);
    if (index == -1) {
      return -1;
    }
    return index;
  }

  // int comparePositions(List<Identifier> pos1, List<Identifier> pos2) {
  //   for (int i = 0; i < pos1.length; i++) {
  //     if (i >= pos2.length) {
  //       return 1; // pos1 comes after pos2 if it has more identifiers
  //     }

  //     if (pos1[i].digit != pos2[i].digit) {
  //       return pos1[i].digit - pos2[i].digit;
  //     }

  //     if (pos1[i].siteId != pos2[i].siteId) {
  //       return pos1[i].siteId.compareTo(pos2[i].siteId);
  //     }
  //   }

  //   if (pos1.length < pos2.length) {
  //     return -1; // pos1 comes before pos2 if it has fewer identifiers
  //   }

  //   return 0; // pos1 and pos2 are equal
  // }
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
