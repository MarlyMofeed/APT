import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:texteditor/views/textEdit.dart';
//import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import 'login.dart';


// void main() {
//   runApp(FileManagementPage());
// }


class Document {
  final int id;
  final String name;
  final String owner;
  final bool isOwnedByUser; // Whether the document is owned by the user or shared by others
  
  

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
  @override
  _FileManagementPageState createState() => _FileManagementPageState();
}

class _FileManagementPageState extends State<FileManagementPage> {

  final Box _boxLogin = Hive.box("login");

  bool isEditor = true;

  List<Document> get ownedDocuments => [
    Document(id: 1, name: 'Document 1', owner: _boxLogin.get("userName") ?? 'Default User', isOwnedByUser: true),
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

  @override
  Widget build(BuildContext context) {
    print("Build method called");

    return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
        title: Row(
          children: <Widget>[
            Icon(Icons.file_copy), // replace with your desired icon
            SizedBox(width: 10), // gives some horizontal space between the icon and the text
            Text("File Management",
              //style: Theme.of(context).textTheme.headlineLarge,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 8,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
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
          )
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 20.0),
            child: Text('Owned Documents',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ownedDocuments.length,
            itemBuilder: (context, index) {
              final document = ownedDocuments[index];
              return ListTile(
                title: Text(ownedDocuments[index].name),
                //subtitle: Text('Owned by: ${ownedDocuments[index].owner}'),
                onTap: () {

                  // Go to the text editor page
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TextEdit()));

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
              );
            },
          ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 20.0), // adjust the value as needed
            child: Text('Shared Documents',
              style: Theme.of(context).textTheme.headlineMedium,
              ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0), // adjust the value as needed
            child: ListView.builder(
            shrinkWrap: true,
            itemCount: sharedDocuments.length,
            itemBuilder: (context, index) {
              final document = sharedDocuments[index];
              //var isEditor;
              return ListTile(
                title: Text(document.name),
                onTap: () {
                  // Handle opening the document
                },
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) => isEditor ? [
                    PopupMenuItem(
                      value: 'Rename',
                      child: Text('Rename'),
                    ),
                    PopupMenuItem(
                      value: 'Share',
                      child: Text('Share'),
                    ),
                    // Add more options as needed
                  ] : [],
                  onSelected: (value) {
                    // Handle selected option
                  },
                ),
              );
            },
          ),
          ),
        ],
      ),


      floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        final _formKey = GlobalKey<FormState>();
        final TextEditingController _controller = TextEditingController();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
            content: Container(
              width: 300,
              height: 155,
            child: Form(
              key: _formKey,
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // add this line
                children: <Widget>[
                  Padding(padding: const EdgeInsets.only(bottom: 5.0, top: 5),
                  child: Text('Enter the document name',
                  //style: Theme.of(context).textTheme.bodyMedium,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                  ),
                  ),
                  TextFormField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Document name"),
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
                            if (_formKey.currentState?.validate() ?? false) {
                              // setState(() {
                              //   ownedDocuments.add(Document(
                              //     id: ownedDocuments.length + 1, 
                              //     name: _controller.text, 
                              //     owner: _boxLogin.get("userName") ?? 'Default User', 
                              //     isOwnedByUser: true
                              //   )); 
                              addDocument(Document(
                                  id: ownedDocuments.length + 1, 
                                  name: 'New Document', 
                                  owner: 'Default User', 
                                  isOwnedByUser: true
                                ));
                                // print owneddocuments list
                              for (var document in ownedDocuments) {
                                  print(document);
                                }
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
      label: Text('New Document'),
      icon: Icon(Icons.add),
    ),
    );
  }
  
  @override
    void setState(VoidCallback fn) {
      super.setState(fn);
    }
}
