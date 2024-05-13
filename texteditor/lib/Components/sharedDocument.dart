import 'package:flutter/material.dart';
import 'package:texteditor/views/file_management.dart';

class SharedDocuments extends StatefulWidget {
  final List<Document> sharedDocuments;
  final bool isEditor;

  const SharedDocuments({
    Key? key,
    required this.sharedDocuments,
    required this.isEditor,
  }) : super(key: key);

  @override
  _SharedDocumentsState createState() => _SharedDocumentsState();
}

class _SharedDocumentsState extends State<SharedDocuments> {
  @override
  Widget build(BuildContext context) {
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
              itemCount: widget.sharedDocuments.length,
              itemBuilder: (context, index) {
                final document = widget.sharedDocuments[index];
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
                      itemBuilder: (context) => widget.isEditor
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
    );
  }
}
