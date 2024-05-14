class Document {
  final String id;
  String name;
  final String owner;
  final bool isOwnedByUser;

  Document({
    required this.id,
    required this.name,
    required this.owner,
    this.isOwnedByUser = false,
    //this.isEditor = true,
  });

  @override
  String toString() {
    return 'Document(id: $id, name: $name, owner: $owner, isOwnedByUser: $isOwnedByUser)';
  }
}
