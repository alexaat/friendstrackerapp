import 'dart:convert';
import 'locations.dart';
class User {
  int id = 0;
  String name = '';
  String email = '';
  String? avatar;
  Status? status;
  String? friends;
  String? accessToken;
  Location? location;
  User({required this.id, required this.name, required this.email, this.avatar, this.friends, this.status, this.accessToken, this.location});
  static User fromJson(Map<String, dynamic> json){
    Location? location =  json['location'] == null ? null : Location(latitude: json['location']['latitude'], longitude: json['location']['longitude'], timestamp:  json['location']['timestamp']);
    return User(
        id: json['id'],
        name: json['name'],
        email: json['email'] ?? 'hidden',
        avatar: json['avatar'],
        friends: jsonEncode(json['friends']),
        accessToken: json['access_token'],
        location: location
    );
  }
}
enum Status {
  free,
  approved,
  awaiting,
  pending
}