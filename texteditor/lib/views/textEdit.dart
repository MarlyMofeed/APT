import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:texteditor/Components/remoteCursor.dart';
import 'package:texteditor/service/CRDT.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class TextEdit extends StatefulWidget {
  final String id;
  final String documentId;

  const TextEdit({
    Key? key,
    required this.id,
    required this.documentId,
  }) : super(key: key);

  @override
  _TextEditState createState() => _TextEditState();
}

class _TextEditState extends State<TextEdit> {
  QuillController _controller = QuillController.basic();
  int _cursorPosition = 0;
  String _previousText = '';
  String operation = '';
  int row = 0;
  int column = 0;
  String? element;
  Timer? _autosaveTimer;
  // String documentId = widget.documentId;
  List<String> content = ['your', 'document', 'content'];
  int version = 0;
  List<Map<String, int>> changesBuffer = [];
  late IO.Socket socket;
  late CRDT crdt;
  int isCaps = 0;
  String previousCharacter = '';
  // String get documentId => widget.documentId;
  int previousStart = 0;
  int previousEnd = 0;
  int currentStart = 0;
  int currentEnd = 0;

  // Add a map to store the cursor positions of all users in the document (siteId -> cursor position)
  // holds userIDs and their cursor positions
  Map<String, int> cursorPositions = {};
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'query': {'id': widget.id, 'documentId': widget.documentId},
    });
    // socket.on('connect', (_) {
    //   print("gowa el connect: ${widget.documentId}");
    //   print('connected');
    // });
    // socket.connect();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleSelectionChange);

    crdt = CRDT();
    // socket = IO.io('http://25.45.201.128:5000', <String, dynamic>{
    //   'transports': ['websocket'],
    //   'query': {'id': widget.id, 'documentId': documentId},
    // });
    print("ha5osh el document ely esmo: ${widget.documentId}");
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'query': {'id': widget.id, 'documentId': widget.documentId},
    });

    socket.on('connect', (_) {
      // socket.connect();
      print("gowa el connect: ${widget.documentId}");

      print('connected');
    });
    try {
      socket.connect();
    } catch (e) {
      print("error: $e");
    }

    // Add a listener to the text controller to track cursor position changes
    // _controller.addListener(() {
    //   if (_controller.selection.start != _cursorPosition) {
    //     _cursorPosition = _controller.selection.start;
    //     socket.emit(
    //         'cursorPosition', {'id': widget.id, 'position': _cursorPosition});
    //   }
    // final cursorPosition = _controller.selection.start;
    // if (cursorPositions[widget.id] != cursorPosition) {
    //   cursorPositions[widget.id] = cursorPosition;
    //   // TODO: Send cursorPosition to the server
    // }
    // });

    // Step 3: Receive cursor position updates from the server
    // socket.on('cursorPosition', (data) {
    //   setState(() {
    //     cursorPositions[data['id']] = data['position'];
    //   });
    // });

    _previousText = _controller.document.toPlainText();
    _autosaveTimer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      _saveDocument(widget.id, widget.documentId, _previousText);
    });
    socket.on('disconnect', (_) {
      print('disconnected');
      print("gowa el disconnect: ${widget.documentId}");
    });
    socket.on('error', (data) => print('error: $data'));

    socket.on('remoteInsert', (data) {
      print("galy REMOTE INSERT");
      print(data);
      Identifier receivedChar = Identifier(
        data['value'],
        data['digit'].toDouble(),
        data['siteId'],
        data['bold'],
        data['italic'],
      );
      print(receivedChar);
      handleRemoteInsert(receivedChar);
    });
    socket.on('remoteDelete', (data) {
      print("galy REMOTE DELETE");
      Identifier receivedChar = Identifier(
        data['value'],
        data['digit'].toDouble(),
        data['siteId'],
        data['bold'],
        data['italic'],
      );
      handleRemoteDelete(receivedChar);
    });
    socket.on('remoteFormatting', (data) {
      print("galy REMOTE FORMATTING");
      List<Identifier> receivedChars = [];
      for (int i = 0; i < data.length; i++) {
      Identifier receivedChar = Identifier(
        data[i]['value'],
        data[i]['digit'].toDouble(),
        data[i]['siteId'],
        data[i]['bold'],
        data[i]['italic'],
      );
      receivedChars.add(receivedChar);
      }
      handleRemoteFormatting(receivedChars);
    });
  }

  @override
  void dispose() {
    print("ana ba despoooozzzzzz");
    socket.disconnect();
    // _autosaveTimer?.cancel();
    super.dispose();
  }

  void _saveDocument(String userId, String documentId, String content) async {
    var url = Uri.parse('http://localhost:8080/document/save');

    var response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'userId': widget.id,
      },
      body: jsonEncode(<String, dynamic>{
        'id': documentId,
        'documentContent': content,
      }),
    );

    if (response.statusCode == 200) {
      print('Document saved successfully');
    } else {
      print('Failed to save document');
    }
  }

  void handleLocalInsert(String value, int index, int bold, int italic) {
    Identifier char = crdt.localInsert(value, index, bold, italic);
    print("HANDLE LOCAL INSERT: $char");
    socket.emit('localInsert', char);
  }

  void handleLocalDelete(int index) {
    Identifier char = crdt.localDelete(index);
    print("HANDLE LOCAL DELETE: $char");
    print("crdt.struct: ${crdt.struct}");
    socket.emit('localDelete', char);
  }

  void handleRemoteInsert(Identifier char) {
    Identifier result = crdt.remoteInsert(char);
    int index = crdt.findIndex(crdt.struct, result) - 1;
    print("index gowa el handle remote insert: $index");
    String value = result.value;
    // Insert the character at the correct position in the text controller
    print("CRDT After remote insert: ${crdt.struct}");
    // Update the cursor positions map when a remote insert occurs
    // cursorPositions
    //     .updateAll((key, value) => value >= index ? value + 1 : value);

    // Apply formatting based on the isBold and isItalic flags
    if (char.bold == 1 && char.italic == 1) {
      _controller.replaceText(index, 0, value,
          TextSelection.collapsed(offset: index + value.length));
      _controller.formatText(index, value.length, Attribute.bold);
      _controller.formatText(index, value.length, Attribute.italic);
    } else if (char.bold == 1) {
      _controller.replaceText(index, 0, value,
          TextSelection.collapsed(offset: index + value.length));
      _controller.formatText(index, value.length, Attribute.bold);
    } else if (char.italic == 1) {
      _controller.replaceText(index, 0, value,
          TextSelection.collapsed(offset: index + value.length));
      _controller.formatText(index, value.length, Attribute.italic);
    } else {
      _controller.replaceText(index, 0, value,
          TextSelection.collapsed(offset: index + value.length));
    }
  }

  void handleRemoteDelete(Identifier char) {
    int indexofRemoval = crdt.remoteDelete(char) - 1;
    print("index of removal: $indexofRemoval");
    // Delete the character at the correct position in the text controller
    if (indexofRemoval != -1) {
      _controller.replaceText(indexofRemoval, 1, '',
          TextSelection.collapsed(offset: indexofRemoval));
    }
    // Update the cursor positions map when a remote delete occurs
    // cursorPositions
    //     .updateAll((key, value) => value >= indexofRemoval ? value - 1 : value);
  }

  void handleRemoteFormatting(List<Identifier> identifiers) {
    for (int i = 0; i < identifiers.length; i++) {
    Identifier char = identifiers[i];
    print(char.digit);
    int index = crdt.findIndexByPosition(char) - 1;
    print("index gowa el handle remote formatting: $index");
    crdt.struct[index + 1] = char;
    if (index != -1) {
      if (char.bold == 1 && char.italic == 1) {
        _controller.formatText(index, char.value.length, Attribute.bold);
        _controller.formatText(index, char.value.length, Attribute.italic);
      } else if (char.bold == 1) {
        _controller.formatText(index, char.value.length, Attribute.bold);
        _controller.formatText(
            index, char.value.length, Attribute.clone(Attribute.italic, null));
      } else if (char.italic == 1) {
        _controller.formatText(index, char.value.length, Attribute.italic);
        _controller.formatText(
            index, char.value.length, Attribute.clone(Attribute.bold, null));
      } else {
        _controller.formatText(
            index, char.value.length, Attribute.clone(Attribute.bold, null));
        _controller.formatText(
            index, char.value.length, Attribute.clone(Attribute.italic, null));
      }
    }
   }
  }

  // ignore: deprecated_member_use
  void _handleKeyPress(RawKeyEvent event) {
    // ignore: deprecated_member_use
    if (event is RawKeyDownEvent) {
      LogicalKeyboardKey logicalKey = event.logicalKey;
      String? keyLabel = logicalKey.keyLabel;

      if (keyLabel == 'Backspace') {
        // Handle backspace key press
        print("insideeee delete");
        operation = 'Delete';
        int deleteIndex = _controller.selection.baseOffset;
        print("deleteIndex: ${deleteIndex}");
        if (deleteIndex >= 0) {
          handleLocalDelete(deleteIndex);
        } else {
          print("Mafesh 7aga yabn el hbla");
        }
      } else if (keyLabel == "Caps Lock") {
        isCaps = 1 - isCaps;
      } else {
        print("insideeee insert");
        if (keyLabel.length > 1) {
          return;
        }
        // Handle other key presses (alphabets, numbers, etc.)
        operation = 'Insert';
        print("Element: $keyLabel");
        print("Ta3deelll");
        if (isCaps != 1) {
          keyLabel = keyLabel!.toLowerCase();
        }

        print("Element: $keyLabel");
        print("position: ${_controller.selection.baseOffset}");

        handleLocalInsert(keyLabel, _controller.selection.baseOffset,
            _isBoldSelected(), _isItalicSelected());
      }
    }
  }

  void getFormatChange() {
    if (currentStart == previousStart &&
        currentEnd == previousEnd &&
        currentStart != currentEnd) {
      Style selectionStyle = _controller.getSelectionStyle();
      Map<String, Attribute> attributes = selectionStyle.attributes;
      bool isBold = attributes.containsKey('bold');
      bool isItalic = attributes.containsKey('italic');

      print('Selected Text Format:');
      print('Bold: $isBold');
      print('Italic: $isItalic');

      List<Identifier> identifiers = List<Identifier>.filled(
          currentEnd - currentStart, Identifier('', 0, '0', 0, 0));
      for (int i = currentStart; i < currentEnd; i++) {
        if (i < crdt.struct.length) {
          crdt.struct[i + 1].bold = isBold ? 1 : 0;
          crdt.struct[i + 1].italic = isItalic ? 1 : 0;
          identifiers[i - currentStart] = crdt.struct[i + 1];
        }
      }
      print(identifiers);
      
      socket.emit('localFormatting',{
        'identifiers': identifiers //.map((e) => e.toJson()).toList(),
      });
      
    }
  }

  void _handleSelectionChange() {
    if (_controller.selection.isValid) {
      previousStart = currentStart;
      previousEnd = currentEnd;
      getSelectedTextIndices();
      getFormatChange();
    }
  }

  void getSelectedTextIndices() {
    TextSelection selection = _controller.selection;

    int start = selection.start;
    int end = selection.end;

    print('Start: $start, End: $end');
    currentStart = start;
    currentEnd = end;
  }

  int _isBoldSelected() {
    Attribute? attribute = _controller.getSelectionStyle().attributes['bold'];
    if (attribute != null) {
      return 1;
    }
    return 0;
  }

  int _isItalicSelected() {
    Attribute? attribute = _controller.getSelectionStyle().attributes['italic'];
    if (attribute != null) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyPress,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.save),
              )
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: QuillToolbar.simple(
                  configurations: QuillSimpleToolbarConfigurations(
                    controller: _controller,
                    sharedConfigurations: const QuillSharedConfigurations(
                      locale: Locale('en'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _controller,
                    showCursor: true,
                    readOnly: false,
                    sharedConfigurations: const QuillSharedConfigurations(
                      locale: Locale('en'),
                    ),
                  ),
                ),
              ),
              Container(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text("Save"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

//   @override
// Widget build(BuildContext context) {
//   return Stack(
//     children: [
//       RawKeyboardListener(
//         focusNode: FocusNode(),
//         onKey: _handleKeyPress,
//         child: SafeArea(
//           child: Scaffold(
//             appBar: AppBar(
//               actions: [
//                 IconButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: Icon(Icons.save),
//                 )
//               ],
//             ),
//             body: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(25.0),
//                   child: QuillToolbar.simple(
//                     configurations: QuillSimpleToolbarConfigurations(
//                       controller: _controller,
//                       sharedConfigurations: const QuillSharedConfigurations(
//                         locale: Locale('en'),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: QuillEditor.basic(
//                     configurations: QuillEditorConfigurations(
//                       controller: _controller,
//                       readOnly: false,
//                       sharedConfigurations: const QuillSharedConfigurations(
//                         locale: Locale('en'),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Container(
//                   width: 200,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       minimumSize: const Size.fromHeight(50),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     onPressed: () {},
//                     child: const Text("Save"),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//       ...cursorPositions.entries.map((entry) {
//         final position = calculateCursorOffset(_controller as TextEditingController, entry.value);
//         return RemoteCursorWidget(position: position, color: Colors.red); // Use a different color for each user
//       }).toList(),
//     ],
//   );
// }
//}