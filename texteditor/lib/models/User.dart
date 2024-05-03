class User {
  String? username;
  String? password;
  String? email;
  List<String?>? documentIds;
  List<String?>? sharedDocumentIds;

  User({
    this.username,
    this.password,
    this.email,
    this.documentIds,
    this.sharedDocumentIds,
  });

  User.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    password = json['password'];
    email = json['email'];
    documentIds = json['documentIds'] != null ? List<String?>.from(json['documentIds']) : null;
    sharedDocumentIds = json['sharedDocumentIds'] != null ? List<String?>.from(json['sharedDocumentIds']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['password'] = this.password;
    data['email'] = this.email;
    data['documentIds'] = this.documentIds;
    data['sharedDocumentIds'] = this.sharedDocumentIds;
    return data;
  }
}