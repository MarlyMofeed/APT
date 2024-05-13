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

  const TextEdit({
    Key? key,
    required this.id,
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

  @override
  void initState() {
    super.initState();
    print("IN TEXT EDIT ID: ${widget.id}");
    print("documentId: $documentId ");
    crdt = CRDT();
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'query': {'id': widget.id, 'documentId': documentId},
    });

    socket.on('connect', (_) {
      print('connected');
    });
    socket.connect();

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
      );
      print(receivedChar);
      handleRemoteInsert(receivedChar);
    });
    socket.on('remoteDelete', (data) {
      handleRemoteDelete(data);
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

  void handleLocalInsert(String value, int index) {
    Identifier char = crdt.localInsert(value, index);
    print("HANDLE LOCAL INSERT: $char");
    socket.emit('localInsert', char);
  }

  void handleLocalDelete(int index) {
    Identifier char = crdt.localDelete(index);
    print("HANDLE LOCAL DELETE: $char");
    socket.emit('localDelete', char);
  }

  void handleRemoteInsert(Identifier char) {
    Identifier result = crdt.remoteInsert(char);
    int index = crdt.findIndex(crdt.struct, result) - 1;
    print("index: $index");
    String value = result.value;
    // Insert the character at the correct position in the text controller
    _controller.replaceText(
        index, 0, value, TextSelection.collapsed(offset: index + value.length));
  }

  void handleRemoteDelete(Map<String, dynamic> char) {
    // int index = crdt.remoteDelete(char);
    // Delete the character at the correct position in the text controller
    // if (index != -1) {
    //   _controller.replaceText(
    //       index, 1, '', TextSelection.collapsed(offset: index));
    // }
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
        int deleteIndex = _controller.selection.baseOffset - 1;
        print("position: ${_controller.selection.baseOffset}");
        if (deleteIndex >= 0) {
          handleLocalDelete(deleteIndex);
        }
      } else {
        print("insideeee insert");
        // Handle other key presses (alphabets, numbers, etc.)
        operation = 'Insert';
        print("Element: $keyLabel");
        print("position: ${_controller.selection.baseOffset}");
        handleLocalInsert(keyLabel, _controller.selection.baseOffset);
      }
    }
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
