import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:texteditor/Components/shareDialog.dart';
import 'package:texteditor/models/Document.dart';
import 'package:texteditor/views/file_management.dart';
import 'package:http/http.dart' as http;
import 'package:texteditor/views/textEdit.dart';
import 'package:texteditor/views/viewOnly.dart';

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
