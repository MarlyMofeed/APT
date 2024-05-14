import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShareDocumentDialog extends StatefulWidget {
  final String documentName;
  final String userId;

  const ShareDocumentDialog({
    Key? key,
    required this.documentName,
    required this.userId,
  }) : super(key: key);

  @override
  _ShareDocumentDialogState createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final TextEditingController _userController = TextEditingController();
  String role = 'viewer';

  Future<void> shareDocument(
      String userId, String documentName, String username, String role) async {
    print('Sharing document $documentName with user $username with role $role');
    final url = Uri.parse('http://localhost:8080/document/share');
    final headers = {'Content-Type': 'application/json', 'userId': userId};
    final body = jsonEncode({
      'documentName': documentName,
      'username': username,
      'role': role,
    });

    final response = await http.post(url, headers: headers, body: body);
    print('Response of share document: ${response.body}');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document shared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['message'] ?? 'Failed to share document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Share Document'),
      content: Container(
        height: 200.0,
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
              await shareDocument(
                  widget.userId, widget.documentName, username, role);
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
