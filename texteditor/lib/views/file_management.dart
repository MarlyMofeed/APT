import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:texteditor/Components/sharedDocument.dart';
import 'package:texteditor/views/textEdit.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

class Document {
  final String id;
  String name;
  final String owner;
  final bool isOwnedByUser;

  Document({
    required this.id,
    required this.name,
    required this.owner,
    required this.isOwnedByUser,
    //this.isEditor = true,
  });

  @override
  String toString() {
    return 'Document(id: $id, name: $name, owner: $owner, isOwnedByUser: $isOwnedByUser)';
  }
}

class FileManagementPage extends StatefulWidget {
  final String id;

  FileManagementPage({Key? key, required this.id}) : super(key: key);

  @override
  _FileManagementPageState createState() => _FileManagementPageState();
}

class _FileManagementPageState extends State<FileManagementPage> {
  final Box _boxLogin = Hive.box("login");

  bool isEditor = true;

  List<Document> ownedDocuments = [];

  final List<Document> sharedDocuments = [
    Document(
        id: "2", name: 'Document 2', owner: 'User 2', isOwnedByUser: false),
  ];

  //FUNCTIONS//
  Future<void> createDocument(String userId, String documentName) async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/document/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'userId': userId,
      },
      body: jsonEncode(<String, String>{
        'documentName': documentName,
      }),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> result = jsonDecode(response.body);
      print(result['message']);
      Map<String, dynamic> document = result['document'];
      Document newDocument = Document(
        id: document['id'].toString(),
        name: document['name'],
        owner: userId,
        isOwnedByUser: true,
      );
      setState(() {
        ownedDocuments.add(newDocument);
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to create document'),
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

  Future<List<Document>> getUserDocuments(String userId) async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/document/user/owns'),
      headers: <String, String>{
        'userId': userId,
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final documentsJson = responseBody['documents'] as List;
      return documentsJson.map((document) {
        return Document(
          id: document['id'].toString(),
          name: document['name'],
          owner: userId,
          isOwnedByUser: true,
        );
      }).toList();
    } else {
      throw Exception('Failed to retrieve the user documents');
    }
  }

  Future<void> deleteDocument(String userId, String documentName) async {
    print('Deleting document');
    print("userId: $userId, documentName: $documentName");
    final response = await http.delete(
      Uri.parse('http://localhost:8080/document/delete'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'userId': userId,
      },
      body: jsonEncode(<String, String>{
        'documentName': documentName,
      }),
    );
    if (response.statusCode == 200) {
      print('Document deleted successfully');
      setState(() {
        ownedDocuments.removeWhere((doc) => doc.name == documentName);
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to delete the document'),
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

  Future<void> updateDocumentName(
      String userId, String oldName, String newName) async {
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

    if (response.statusCode == 200) {
      print('Document updated successfully');
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

  void renameDocument(String userId, String oldName) {
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
                  await updateDocumentName(userId, oldName, newName);
                  setState(() {
                    Document updatedDocument = ownedDocuments.firstWhere(
                      (doc) => doc.name == oldName,
                    );
                    updatedDocument.name = newName;
                  });
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

//END OF FUNCTIONS//
  @override
  void initState() {
    super.initState();
    getUserDocuments(widget.id).then((documents) {
      setState(() {
        ownedDocuments = documents;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                _boxLogin.clear();
                _boxLogin.put("loginStatus", false);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const Login();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50.0, bottom: 50.0),
              child: Text(
                "File Management",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Owned Documents',
                        style: TextStyle(
                          fontSize: 26,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      //),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(150, 30, 150, 100),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: ownedDocuments.length,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final document = ownedDocuments[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                title: Text(ownedDocuments[index].name),
                                //subtitle: Text('Owned by: ${ownedDocuments[index].owner}'),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => TextEdit(
                                                id: widget.id,
                                              )));
                                },
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'Delete',
                                      child: Text('Delete'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Rename',
                                      child: Text('Rename'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Share',
                                      child: Text('Share'),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    // TODO: Handle selected option
                                    if (value == 'Delete') {
                                      deleteDocument(widget.id,
                                          ownedDocuments[index].name);
                                    }
                                    if (value == 'Rename') {
                                      renameDocument(widget.id,
                                          ownedDocuments[index].name);
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
                ),
                SizedBox(width: 50),
                SharedDocuments(
                    sharedDocuments: sharedDocuments, isEditor: isEditor),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16.0),
        width: 300,
        child: FloatingActionButton.extended(
          onPressed: () {
            final _formKey = GlobalKey<FormState>();
            final TextEditingController _controller = TextEditingController();
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Container(
                    width: 300,
                    height: 170,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 13.0, top: 5),
                            child: Text(
                              'Enter the document name',
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          TextFormField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Document name",
                              prefixIcon: const Icon(Icons.file_copy),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Document name cannot be empty';
                              }
                              return null;
                            },
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextButton(
                                  child: Text('Done'),
                                  onPressed: () {
                                    String documentName = _controller.text;
                                    if (documentName.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please enter document name'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } else {
                                      createDocument(widget.id, documentName);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          label: Text(
            'New Document',
            style: TextStyle(
              color: Color.fromARGB(255, 15, 113, 193),
            ),
          ),
          icon: Icon(Icons.add,
              size: 17, color: Color.fromARGB(255, 15, 113, 193)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
