class Invites {
  List<Incoming>? incoming = [];
  List<Outgoing>? outgoing = [];
  Invites({this.incoming, this.outgoing});
  Invites.fromJson(Map<String, dynamic> json) {
    incoming = List<Incoming>.from(json['incoming'].map((model)=> Incoming.fromJson(model)));
    outgoing = List<Outgoing>.from(json['outgoing'].map((model)=> Outgoing.fromJson(model)));
  }
}
class Incoming {
  int id;
  Person sender;
  Incoming({required this.id, required this.sender});
  static fromJson(Map<String, dynamic> json){
    Person sender = Person.fromJson(json['sender']);
    return Incoming(id: json['id'], sender: sender);
  }
}
class Outgoing{
  int id;
  Person recipient;
  Outgoing({required this.id, required this.recipient});
  static fromJson(Map<String, dynamic> json){
    Person recipient = Person.fromJson(json['recipient']);
    return Outgoing(id: json['id'], recipient: recipient);
  }
}
class Person {
  int id;
  String name;
  String? avatar = '';
  Person({required this.id, required this.name, this.avatar});
  static fromJson(Map<String, dynamic> json){
    return Person(
        id: json["id"],
        name: json["name"],
        avatar: json["avatar"]
    );
  }
}