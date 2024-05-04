import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/services.dart';

class TextEdit extends StatefulWidget {
  const TextEdit({
    Key? key,
  }) : super(key: key);

  @override
  _TextEditState createState() => _TextEditState();
}

class _TextEditState extends State<TextEdit> {
  QuillController _controller = QuillController.basic();
  late IOWebSocketChannel channel;
  int _cursorPosition = 0;

  @override
  void initState() {
    super.initState();
    //channel = IOWebSocketChannel.connect('ws://localhost/document/updateContent');

    // Listen to the onChange event of the QuillController
    _controller.addListener(() {
      // Convert the document to plain text
      String documentText = _controller.document.toPlainText();

      // Send the document text to the WebSocket server
     // channel.sink.add(documentText);
      print(documentText);
      
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

 

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
    );
  }
}