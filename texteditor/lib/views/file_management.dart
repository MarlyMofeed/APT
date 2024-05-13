import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:texteditor/views/textEdit.dart';
import 'package:http/http.dart' as http;

//import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import 'login.dart';

// void main() {
//   runApp(FileManagementPage());
// }

class Document {
  final int id;
  final String name;
  final String owner;
  final bool
      isOwnedByUser; // Whether the document is owned by the user or shared by others

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

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     print('Build method called');

//     return MaterialApp(
//       home: FileManagementPage(),
//     );
//   }
// }

class FileManagementPage extends StatefulWidget {
  final String id;

  FileManagementPage({Key? key, required this.id}) : super(key: key);

  @override
  _FileManagementPageState createState() => _FileManagementPageState();
}

class _FileManagementPageState extends State<FileManagementPage> {
  final Box _boxLogin = Hive.box("login");

  bool isEditor = true;

  List<Document> ownedDocuments = [
    Document(id: 1, name: 'Document 1', owner: 'User 1', isOwnedByUser: true),
    // Add more owned documents here
  ];

  final List<Document> sharedDocuments = [
    Document(id: 2, name: 'Document 2', owner: 'User 2', isOwnedByUser: false),
    // Add more shared documents here
  ];

  void addDocument(Document document) {
    setState(() {
      ownedDocuments.add(document);
    });
  }

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
      print(result['message']); // Document added successfully

      Map<String, dynamic> document = result['document'];
      print('Document ID: ${document['id']}');
      print('Document Name: ${document['name']}');
      print('Owner ID: ${document['ownerId']}');
    } else {
      throw Exception('Failed to add document');
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Build method called");

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        //backgroundColor: Colors.white,
        // title: Row(
        //   children: <Widget>[
        //     //Icon(Icons.file_copy), // replace with your desired icon
        //     SizedBox(width:10), // gives some horizontal space between the icon and the text
        //     Text(
        //       "File Management",
        //       //style: Theme.of(context).textTheme.headlineLarge,
        //       style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        //     ),
        //   ],
        // ),
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
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50.0, bottom: 50.0),
              child: Text(
                "File Management",
                //style: Theme.of(context).textTheme.headlineLarge,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),

            // Padding(
            //   padding: const EdgeInsets.only(top: 70.0),
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
                                  // Go to the text editor page
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
                //Padding(
                //padding: const EdgeInsets.only(left: 20.0),

                Expanded(
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
                      //),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(150, 30, 150, 100),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: sharedDocuments.length,
                          itemBuilder: (context, index) {
                            final document = sharedDocuments[index];
                            //var isEditor;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                title: Text(document.name),
                                onTap: () {
                                  // TODO: Handle opening the document
                                },
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (context) => isEditor
                                      ? [
                                          PopupMenuItem(
                                            value: 'Rename',
                                            child: Text('Rename'),
                                          ),
                                          PopupMenuItem(
                                            value: 'Share',
                                            child: Text('Share'),
                                          ),
                                          // Add more options as needed
                                        ]
                                      : [],
                                  onSelected: (value) {
                                    // Handle selected option
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // add this line
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 13.0, top: 5),
                            child: Text(
                              'Enter the document name',
                              //style: Theme.of(context).textTheme.bodyMedium,
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
                                    createDocument(widget.id, documentName);
                                    Navigator.of(context).pop();
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
              // make colour dark blue
              color: Color.fromARGB(255, 15, 113, 193),
            ),
          ),
          icon: Icon(Icons.add,
              size: 17, color: Color.fromARGB(255, 15, 113, 193)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
          // align button in middle of screen
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // @override
  //   void setState(VoidCallback fn) {
  //     super.setState(fn);
  //   }
}
