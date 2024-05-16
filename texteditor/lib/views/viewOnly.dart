import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:dart_quill_delta/dart_quill_delta.dart' as quill_delta;

import 'package:texteditor/service/CRDT.dart';

class ViewOnly extends StatefulWidget {
  final String id;
  final String documentId;

  const ViewOnly({
    Key? key,
    required this.id,
    required this.documentId,
  }) : super(key: key);

  @override
  _ViewOnlyState createState() => _ViewOnlyState();
}

class _ViewOnlyState extends State<ViewOnly> {
  QuillController _controller = QuillController.basic();
  late IO.Socket socket;
  late CRDT crdt;
  late quill.Document _document;

  @override
  void initState() {
    super.initState();

    crdt = CRDT();
    socket = IO.io('http://25.45.201.128:5000', <String, dynamic>{
      'transports': ['websocket'],
      'query': {'id': widget.id, 'documentId': widget.documentId},
    });

    socket.on('connect', (_) {
      print('connected');
    });
    socket.connect();

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

    socket.on('receiveDocument', (data) {
      // Handle the received data as a list
      List<dynamic> crdtContent = data;
      List<Identifier> crdtContentList = [];
      for (int i = 0; i < crdtContent.length; i++) {
        Identifier char = Identifier(
          crdtContent[i]['value'],
          crdtContent[i]['digit'].toDouble(),
          crdtContent[i]['siteId'],
          crdtContent[i]['bold'],
          crdtContent[i]['italic'],
        );
        crdtContentList.add(char);
      }
      crdt.struct = crdtContentList;
      _controller.moveCursorToEnd();
      print(crdtContentList);
      // Handle the received CRDT content

      handleReceivedCrdtContent(
          crdtContentList.sublist(1, crdtContentList.length - 1));
    });
  }

  @override
  void dispose() {
    print("ana ba despoooozzzzzz");
    crdt.struct.clear();
    socket.disconnect();
    super.dispose();
  }

  void handleReceivedCrdtContent(List<dynamic> crdtContent) {
    print(
        "Received DOCUMENT CONTENT =============================================================================");

    // Creating the content array
    List<Map<String, dynamic>> contentArray = crdtContent.map((item) {
      return {
        'char': item.value,
        'bold': item.bold,
        'italic': item.italic,
      };
    }).toList();

    // Adding a newline character at the end
    contentArray.add({'char': '\n', 'bold': 0, 'italic': 0});

    print(contentArray);

    // Creating a Delta from the content array
    var delta = quill_delta.Delta();
    for (int i = 0; i < contentArray.length; i++) {
      var item = contentArray[i];
      var attributes = <String, dynamic>{};
      if (item['bold'] == 1) {
        attributes['bold'] = true;
      }
      if (item['italic'] == 1) {
        attributes['italic'] = true;
      }

      // Create a new delta for each character
      var charDelta = quill_delta.Delta();
      charDelta.insert(item['char'], attributes);

      // Add the new delta to the existing delta
      delta = delta.concat(charDelta);
    }
    // Creating a Document from the Delta
    _controller.document = quill.Document.fromDelta(delta);
    print("ddeltaaaa");
    print(delta);

    // Initializing the QuillController with the Document
    // _controller = QuillController(
    //   document: _document,
    //   selection: const TextSelection.collapsed(offset: 0),
    // );

    // Rebuild the UI with the new controller
    if (mounted) {
      setState(() {});
    }
  }

  void handleRemoteInsert(Identifier char) {
    Identifier result = crdt.remoteInsert(char);
    int index = crdt.findIndex(crdt.struct, result) - 1;
    print("index: $index");
    String value = result.value;
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
              icon: const Icon(Icons.save),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _controller,
                  //showCursor: true,
                  readOnly: true,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
