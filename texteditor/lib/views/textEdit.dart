import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:texteditor/service/CRDT.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

// import 'package:uuid/uuid.dart';

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
  String documentId = '6633ad108901bd48cf18bb60';
  List<String> content = ['your', 'document', 'content'];
  int version = 0;
  List<Map<String, int>> changesBuffer = [];
  late IO.Socket socket;
  late CRDT crdt;
  int isCaps = 0;
  String previousCharacter = '';

  @override
  void initState() {
    super.initState();
    crdt = CRDT();
    // socket = IO.io('http://25.45.201.128:5000', <String, dynamic>{
    //   'transports': ['websocket'],
    //   'query': {'id': widget.id, 'documentId': documentId},
    // });
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'query': {'id': widget.id, 'documentId': documentId},
    });

    socket.on('connect', (_) {
      print('connected');
    });
    try {
      socket.connect();
    } catch (e) {
      print("error: $e");
    }

    _previousText = _controller.document.toPlainText();
    _autosaveTimer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      _saveDocument(widget.id, documentId, _previousText);
    });
    socket.on('disconnect', (_) => print('disconnected'));
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
  }

  @override
  void dispose() {
    socket.disconnect();
    _autosaveTimer?.cancel();
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
