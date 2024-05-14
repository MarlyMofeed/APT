import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:texteditor/service/CRDT.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class ViewOnly extends StatefulWidget {
  final String id;

  const ViewOnly({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  _ViewOnlyState createState() => _ViewOnlyState();
}

class _ViewOnlyState extends State<ViewOnly> {
  QuillController _controller = QuillController.basic();
  late IO.Socket socket;
  late CRDT crdt;

  @override
  void initState() {
    super.initState();
    crdt = CRDT();
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'query': {'id': widget.id, 'documentId': '6633ad108901bd48cf18bb60'},
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
      handleRemoteDelete(data);
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
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

  void handleRemoteDelete(Map<String, dynamic> char) {
    // int index = crdt.remoteDelete(char);
    // Delete the character at the correct position in the text controller
    // if (index != -1) {
    //   _controller.replaceText(
    //       index, 1, '', TextSelection.collapsed(offset: index));
    // }
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
            Expanded(
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _controller,
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
