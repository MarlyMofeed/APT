import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:web_socket_channel/html.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    print("IN TEXT EDIT ID: ${widget.id}");
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'query': {'id': widget.id},
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
        'userId': userId,
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

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      LogicalKeyboardKey logicalKey = event.logicalKey;
      String? keyLabel = logicalKey.keyLabel ?? logicalKey.debugName;
      //print('Key pressed: $keyLabel');
      if (keyLabel == 'Backspace') {
        operation = 'Delete';
      } else if (keyLabel == 'Enter') {
        operation = 'Insert';
        element = 'New Line';
        row++;
      } else {
        operation = 'Insert';
        element = keyLabel;
      }
      //print('Cursor position: $_cursorPosition'); //not accurate awy aw msh fhma howa shaghal ezay?
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
