
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/invites.dart';
import '../models/locations.dart';
import '../models/user.dart';
import '../utils/constants.dart';


class FriendsTrackerApi {
  static Future<String> getDomain() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String ip = prefs.getString(IP) ?? defaultIP;
    final String port = prefs.getString(PORT) ?? defaultPort;
    return "http://$ip:$port/";
  }
  static Future<List<User>?> getFriends(token) async{
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}friends");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    var response = await http.get(url, headers: requestHeaders);
    if(response.body.isEmpty){
      return [];
    }
    final List<dynamic> list = json.decode(response.body);
    List<User> users = List<User>.from(list.map((model)=> User.fromJson(model)));
    return users;
  }
  static Future<List<User>?> findUsers(token, search) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}users?search=$search");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    var response = await http.get(url, headers: requestHeaders);
    final List<dynamic> list = json.decode(response.body);
    List<User> users = List<User>.from(list.map((model)=> User.fromJson(model)));
    return users;
  }
  static Future<User?> findUser(token, id) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}users/$id");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    var response = await http.get(url, headers: requestHeaders);
    final Map<String, dynamic> userJson = json.decode(response.body);
    User user = User.fromJson(userJson);
    return user;
  }
  static Future<Invites> getInvites(token, id) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}invites/$id");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    var response = await http.get(url, headers: requestHeaders);
    Invites invites = Invites.fromJson(json.decode(response.body));
    return invites;
  }
  static Future<User> authenticate(token) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}auth");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    var response = await http.post(url, headers: requestHeaders);
    User user = User.fromJson(json.decode(response.body));
    return user;
  }
  static Future<void> sendInvite(token, id) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}invites/$id");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    await http.post(url, headers: requestHeaders);
  }
  static Future<void> acceptInvite(token, id) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}invites/$id/accept");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    await http.post(url, headers: requestHeaders);
  }
  static Future<void> declineInvite(token, id) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}invites/$id/decline");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    await http.post(url, headers: requestHeaders);
  }
  static Future<void> updateLocation(String token, Location location) async{
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}locations");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    Map data = {
      "latitude": location.latitude,
      "longitude": location.longitude
    };
    var body = json.encode(data);
    await http.post(
        url,
        headers: requestHeaders,
        body: body
    );
  }
  static Future<void> deleteFriend(token, id) async {
    String domain = await getDomain();
    Uri url = Uri.parse("${domain}friends/$id");
    Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'authorization': token
    };
    await http.delete(url, headers: requestHeaders);
  }
}