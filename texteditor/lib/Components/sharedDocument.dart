import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:texteditor/Components/shareDialog.dart';
import 'package:texteditor/models/Document.dart';
import 'package:texteditor/views/file_management.dart';
import 'package:http/http.dart' as http;
import 'package:texteditor/views/textEdit.dart';
import 'package:texteditor/views/viewOnly.dart';

enum DocumentType { editor, viewer }

class SharedDocuments extends StatefulWidget {
  final String userId;

  const SharedDocuments({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _SharedDocumentsState createState() => _SharedDocumentsState();
}

class _SharedDocumentsState extends State<SharedDocuments> {
  final List<Document> editorDocuments = [];
  final List<Document> viewerDocuments = [];

  Future<Map<String, dynamic>> getSharedDocuments(String userId) async {
    print('Getting shared documents for user $userId');
    final response = await http.get(
      Uri.parse('http://localhost:8080/document/user/shared'),
      headers: <String, String>{
        'userId': userId,
      },
    );
    print('response of get shared documents${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load shared documents');
    }
  }

  Future<void> updateDocumentName(String userId, String oldName, String newName,
      DocumentType docType) async {
    print('Updating document name' + oldName + newName + docType.toString());
    var url = 'http://localhost:8080/document/update';
    var headers = {
      'Content-Type': 'application/json',
      'userId': userId,
    };
    var body = jsonEncode({
      'documentName': oldName,
      'newDocumentName': newName,
    });

    var response = await http.put(Uri.parse(url), headers: headers, body: body);
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('Document updated successfully');
      setState(() {
        Document updatedDocument;
        if (docType == DocumentType.editor) {
          updatedDocument = editorDocuments.firstWhere(
            (doc) => doc.name == oldName,
          );
        } else {
          updatedDocument = viewerDocuments.firstWhere(
            (doc) => doc.name == oldName,
          );
        }
        updatedDocument.name = newName;
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to update the document name'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void renameDocument(String userId, String oldName, DocumentType docType) {
    print('Renaming document' + oldName + docType.toString());
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename Document'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "New Document Name",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Done'),
              onPressed: () async {
                String newName = _controller.text.trim();
                if (newName.isNotEmpty) {
                  print("ha call rename document ");
                  await updateDocumentName(userId, oldName, newName, docType);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a new document name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void loadSharedDocuments() async {
    try {
      Map<String, dynamic> sharedDocuments =
          await getSharedDocuments(widget.userId);
      setState(() {
        for (var doc in sharedDocuments['editorDocuments']) {
          editorDocuments.add(Document(
              id: doc['id'],
              name: doc['name'],
              owner: doc['ownerId'],
              isOwnedByUser: false));
        }
        for (var doc in sharedDocuments['viewerDocuments']) {
          viewerDocuments.add(Document(
              id: doc['id'],
              name: doc['name'],
              owner: doc['ownerId'],
              isOwnedByUser: false));
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    loadSharedDocuments();
  }

  @override
  Widget build(BuildContext context) {
    List<Document> combinedDocuments = [...editorDocuments, ...viewerDocuments];

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Shared Documents',
            style: TextStyle(
              fontSize: 26,
            ),
            textAlign: TextAlign.left,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150, 30, 150, 100),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: combinedDocuments.length,
              itemBuilder: (context, index) {
                final document = combinedDocuments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text(document.name),
                    onTap: () {
                      if (editorDocuments.contains(document)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TextEdit(
                              id: widget.userId,
                              documentId: document.id,
                            ),
                          ),
                        );
                      } else if (viewerDocuments.contains(document)) {
                        print('Viewing document');
                        print(document.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewOnly(
                              id: widget.userId,
                              documentId: document.id,
                            ),
                          ),
                        );
                      }
                    },
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) {
                        if (!viewerDocuments.contains(document)) {
                          return [
                            PopupMenuItem(
                              value: 'Rename',
                              child: Text('Rename'),
                            ),
                            PopupMenuItem(
                              value: 'Share',
                              child: Text('Share'),
                            ),
                          ];
                        } else {
                          return [
                            PopupMenuItem(
                              value: 'Rename',
                              child: Text('Rename'),
                            ),
                          ];
                        }
                      },
                      onSelected: (value) {
                        if (value == 'Share') {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ShareDocumentDialog(
                                userId: widget.userId,
                                documentName: document.name,
                              );
                            },
                          );
                        }
                        if (value == 'Rename') {
                          renameDocument(
                              widget.userId,
                              document.name,
                              editorDocuments.contains(document)
                                  ? DocumentType.editor
                                  : DocumentType.viewer);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
