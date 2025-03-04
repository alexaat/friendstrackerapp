import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/models/user.dart';

class CurrentUserNotifier extends Notifier<User?>{
  @override
  User? build() {
    return null;
  }
  void setCurrentUser(User user){
    state = user;
  }
}
final currentUserNotifierProvider = NotifierProvider<CurrentUserNotifier, User?>(()  {
  return CurrentUserNotifier();
});