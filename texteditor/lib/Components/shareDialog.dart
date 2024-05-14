import 'package:flutter/material.dart';

class ShareDocumentDialog extends StatefulWidget {
  @override
  _ShareDocumentDialogState createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final TextEditingController _userController = TextEditingController();
  String role = 'viewer';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share Document'),
      content: Container(
        height: 200.0, // Set the height to your desired value
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  hintText: "Username",
                ),
              ),
              ListTile(
                title: const Text('Viewer'),
                leading: Radio<String>(
                  value: 'viewer',
                  groupValue: role,
                  onChanged: (String? value) {
                    setState(() {
                      role = value!;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Editor'),
                leading: Radio<String>(
                  value: 'editor',
                  groupValue: role,
                  onChanged: (String? value) {
                    setState(() {
                      role = value!;
                    });
                  },
                ),
              ),
            ],
          ),
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
            String username = _userController.text.trim();
            if (username.isNotEmpty) {
              // TODO: Share the document with the specified user and role
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter a username'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
