import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/api/friends_tracker_api.dart';
import 'package:friendstrackerapp/models/user.dart';
import 'package:friendstrackerapp/providers/current_user_provider.dart';
import 'package:friendstrackerapp/providers/friends_provider.dart';
import 'package:friendstrackerapp/components/menu_item.dart';
import 'package:badges/badges.dart' as badges;

class AwaitingUsersMenu extends ConsumerStatefulWidget {
  const AwaitingUsersMenu({super.key});
  @override
  ConsumerState<AwaitingUsersMenu> createState() => _AwaitingUsersMenuState();
}
class _AwaitingUsersMenuState extends ConsumerState<AwaitingUsersMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  User? currentUser;
  List<Widget>? children;
  MenuController? _controller;
  Timer? updateChildrenTimer;
  void acceptHandler(id) async {
    _controller?.close();
    FriendsTrackerApi.acceptInvite(currentUser!.accessToken, id)
        .then((_){
      FriendsTrackerApi.getFriends(currentUser!.accessToken)
          .then((friends) {
        ref.read(friendsNotifierProvider.notifier).setFriends(friends ?? []);
        setState(() {
          children = null;
        });
      })
          .onError((Object error, StackTrace stackTrace){
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get friends from database: $error')));
        }
      });
    })
        .onError((Object error, StackTrace stackTrace){
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not write to database: $error')));
      }
    });
  }
  void declineHandler(id){
    _controller?.close();
    FriendsTrackerApi.declineInvite(currentUser?.accessToken, id)
        .then((_) {
      setState(() {
        children = null;
      });
    })
        .onError((Object error, StackTrace stackTrace){
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not write to database: $error')));
      }
    });
  }
  void getAwaitingChildren(){
    FriendsTrackerApi.getInvites(currentUser!.accessToken, currentUser!.id)
        .then((invites) {
      List<User> awaiting = invites.incoming?.map((item) => User(id: item.sender.id, name: item.sender.name, email: '', avatar: item.sender.avatar, status: Status.awaiting)).toList() ?? [];
      List<Widget> childrenLocal = [];
      for (var user in awaiting) {
        Widget child = MenuItem(user, onCloseCallback, acceptHandler, declineHandler);
        childrenLocal.add(child);
      }
      setState(() {
        children = childrenLocal;
      });
    })
        .onError((Object error, StackTrace stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get invites from database: $error')));
      }
    });
  }
  @override
  void initState() {
    updateChildrenTimer = Timer.periodic(const Duration(seconds: 5), (Timer t) =>  getAwaitingChildren());
    super.initState();
  }
  @override
  void dispose() {
    _buttonFocusNode.dispose();
    updateChildrenTimer?.cancel();
    super.dispose();
  }
  void onCloseCallback() {
    _controller?.close();
  }
  @override
  Widget build(BuildContext context) {
    currentUser = ref.watch(currentUserNotifierProvider);
    if(children == null){
      getAwaitingChildren();
    }
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: children ?? [],
      builder: (_, MenuController controller, Widget? child) {
        _controller = controller;
        return IconButton(
            focusNode: _buttonFocusNode,
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon:
            children == null ?
            const Icon(Icons.notifications)
                : children!.isEmpty ?
            const Icon(Icons.notifications)
                :
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -14, end: -12),
              badgeContent: Text(
                '${children!.length}',
                style: const TextStyle(
                    color: Colors.white
                ),
              ),
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.teal.shade900,
              ),
              child: const Icon(Icons.notifications),
            )
        );
      },
    );
  }
}