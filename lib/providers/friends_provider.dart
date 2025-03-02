import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/models/user.dart';

class FriendsNotifier extends Notifier<List<User>>{
  @override
  List<User> build() {
    return [];
  }
  void setFriends(List<User> users){
    state = users;
  }
}
final friendsNotifierProvider = NotifierProvider<FriendsNotifier, List<User>>(()  {
  return FriendsNotifier();
});