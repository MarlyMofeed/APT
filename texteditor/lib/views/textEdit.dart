import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/html.dart';


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


  @override
  void initState() {
    super.initState();
    _previousText = _controller.document.toPlainText();
    try {
      channel = HtmlWebSocketChannel.connect('ws://localhost:8080/document/editContent/socket');
      print('Connected to WebSocket server!');
      channel.stream.listen((message) 
      {
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
        row = addedIndex ~/171;
        column = addedIndex % 171;
      } else if (currentText.length < _previousText.length) {
        int removedIndex = _findRemovedIndex(_previousText, currentText);
        //print('Text removed at index: $removedIndex');
        row =  removedIndex~/171;
        column = removedIndex % 171;
      }
      _previousText = currentText;
      if(operation == 'Insert'){
        channel.sink.add('Insert $element $row $column');
        //print('$operation $element in row: $row , column: $column');
      }
      else if(operation == 'Delete'){
        channel.sink.add('Delete $row $column');
        //print('$operation from row: $row , column: $column');

      }
      //_cursorPosition = _controller.selection.baseOffset; // Update cursor position
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

 void _handleKeyPress(RawKeyEvent event) {
  if (event is RawKeyDownEvent) {
    LogicalKeyboardKey logicalKey = event.logicalKey;
    String? keyLabel = logicalKey.keyLabel ?? logicalKey.debugName;
    //print('Key pressed: $keyLabel');
    if(keyLabel == 'Backspace'){
      operation = 'Delete';
    }
    else if(keyLabel == 'Enter')
    {
      operation = 'Insert';
      element = 'New Line';
      row++;
    }
      else{
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
