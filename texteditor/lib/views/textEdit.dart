import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/html.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

//pendingOperation=Null
//changesBufferQueue = null initially
//version=0 on start
//document = null

//onStart() -> init state {
//get document from server
//version = doc.version
//  document = doc.content}

//handleEdit(change) -> change da howa eli bngebo mn el key press already m3mol
//{
//document.apply(change) -> da already byhsal
//hatzawedo if pending==null
//then pending = {change, version}
//send to server
//
//if pending not null -> changeBuffer.add(change)}

//transformPending(change) -> banadeha lama el server yb3tli nack AKA not my applied or pending operation
//{
//version++
// document.applyChange(change)
// if pending msh b null
// bagy hena a3ml transformation lel pending operation wel transorm mwgod fl BE khodoh w transform to flutter hena
// then update el version
// then for each element gowa el changes buffer brdo apply transformation 3shan lazm}

//processMessage(replyFromServer)
//{
//if reply == pending -> hasal ack, hasheel el pending arg3o b null then version++
//check law el changes buffer not empty, if yes put first one in pending and send to server
//
//if reply != pending (version of received law equals my own version) -> hasal nack
//ely ha3mlo hena ha add el change da to my document version, transform my pending and all changes inside changes buffer then
//resend the pending after transformation
//
//3andi case en el client momkn ykon several versions behind, fata7 mt2khr aw connection issues aw whatever wl changes de not yet autosaved to db
//eli mfrod yehsl hena b2a en fe haga fl server esmha send updates byb3t el saved updates eli 3ndo according to version
//client hena byakhod el buffer da w y apply transformation l kol element in the buffer tol ma el version > my own version until i catch up
//}

//changesbuffer in backend = [insert a at 0 0, insert b at 0 1, delete at 0 0]
// el kalam da FEL BACKEND
// this means en insert a at 0 0 de heya version 0 of document
// insert b at 0 1 de heya version 1 of document
// delete at 0 0 de heya version 2 of document

class TextEdit extends StatefulWidget {
  const TextEdit({
    Key? key,
  }) : super(key: key);

  @override
  _TextEditState createState() => _TextEditState();
}

//Column position = index mod 171
//Row position = index // 171

class _TextEditState extends State<TextEdit> {
  QuillController _controller = QuillController.basic();
  late HtmlWebSocketChannel channel;
  int _cursorPosition = 0;
  String _previousText = '';
  String operation = '';
  int row = 0;
  int column = 0;
  String? element;
  Timer? _autosaveTimer;
  String userId = '6633742c11cf8763d7b4b5f3';
  String documentId = '6633ad108901bd48cf18bb60';
  List<String> content = ['your', 'document', 'content'];
  int version = 0;
  List<Map<String, int>> changesBuffer = [];

  @override
  void initState() {
    super.initState();
    _previousText = _controller.document.toPlainText();
    //version = document.ge;
    _autosaveTimer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      _saveDocument(userId, documentId, _previousText);
    });

    try {
      channel = HtmlWebSocketChannel.connect(
          'ws://localhost:8080/document/editContent/socket');
      print('Connected to WebSocket server!');
      channel.stream.listen(
        (message) {
          print('FRONTEND Received message: $message');
        },
        onError: (error) {
          print('Error NOT listening to stream: $error');
        },
      );
    } catch (e) {
      print('Error establishing WebSocket connection: $e');
    }

    // Listen to the onChange event of the QuillController
    _controller.addListener(() {
      String currentText = _controller.document.toPlainText();
      if (currentText.length > _previousText.length) {
        int addedIndex = _findAddedIndex(_previousText, currentText);
        //print('Text added at index: $addedIndex');
        row = addedIndex ~/ 171;
        column = addedIndex % 171;
      } else if (currentText.length < _previousText.length) {
        int removedIndex = _findRemovedIndex(_previousText, currentText);
        //print('Text removed at index: $removedIndex');
        row = removedIndex ~/ 171;
        column = removedIndex % 171;
      }
      _previousText = currentText;
      if (operation == 'Insert') {
        channel.sink.add('Insert $element $row $column');
        //print('$operation $element in row: $row , column: $column');
      } else if (operation == 'Delete') {
        channel.sink.add('Delete $row $column');
        //print('$operation from row: $row , column: $column');
      }
      //_cursorPosition = _controller.selection.baseOffset; // Update cursor position
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  // void _saveDocument() {
  //   print('Saving document...');
  //   String currentText = _controller.document.toPlainText(); // Get the current text in the document
  //   print('Document content: $currentText');
  //   // Save the document to the server
  //   channel.sink.add('Save $currentText');
  // }

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

  int _findAddedIndex(String previousText, String currentText) {
    for (int i = 0; i < currentText.length; i++) {
      if (i >= previousText.length || previousText[i] != currentText[i]) {
        return i;
      }
    }
    return -1;
  }

  int _findRemovedIndex(String previousText, String currentText) {
    for (int i = 0; i < previousText.length; i++) {
      if (i >= currentText.length || previousText[i] != currentText[i]) {
        return i;
      }
    }
    return -1;
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
