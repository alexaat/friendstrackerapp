import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/api/friends_tracker_api.dart';
import 'package:friendstrackerapp/models/user.dart';
import 'package:friendstrackerapp/providers/current_user_provider.dart';
import 'package:friendstrackerapp/providers/friends_provider.dart';
import 'package:friendstrackerapp/components/menu_item.dart';
import 'package:badges/badges.dart' as badges;
import 'package:friendstrackerapp/models/invites.dart';
import 'package:friendstrackerapp/providers/invites_provider.dart';

class AwaitingUsersMenu extends ConsumerStatefulWidget {
  const AwaitingUsersMenu({super.key});
  @override
  ConsumerState<AwaitingUsersMenu> createState() => _AwaitingUsersMenuState();
}

class _AwaitingUsersMenuState extends ConsumerState<AwaitingUsersMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  User? currentUser;
  Invites? invites;
  List<Widget>? children;
  MenuController? _controller;
  Timer? updateInvitesTimer;

  void acceptHandler(id) async {
    _controller?.close();

    if (invites != null){
      List<Incoming>? incoming = invites?.incoming;
      if (incoming != null && incoming.isNotEmpty){
        // update friends list locally
        List<Incoming> incomingFriend = incoming.where((inc) =>  inc.sender.id == id).toList();
        Person sender = incomingFriend[0].sender;
        User friend = User(id: sender.id, name: sender.name, email: '');
        List<User> friends = ref.watch(friendsNotifierProvider);
        friends.add(friend);
        ref.read(friendsNotifierProvider.notifier).setFriends(friends);
        // update invites list locally
        List<Incoming> filtered = incoming.where((inc) => inc.sender.id != id).toList();
        invites!.incoming = filtered;
        ref.read(invitesNotifierProvider.notifier).setInvites(invites!);
      }
    }

    FriendsTrackerApi.acceptInvite(currentUser!.accessToken, id).then((_){
      FriendsTrackerApi.getFriends(currentUser!.accessToken).then((friends) {
        ref.read(friendsNotifierProvider.notifier).setFriends(friends ?? []);
        setState(() {
          children = null;
        });
      }).onError((Object error, StackTrace stackTrace){
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get friends from database: $error')));
        }
      });
    }).onError((Object error, StackTrace stackTrace){
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not write to database: $error')));
      }
    });
  }
  void declineHandler(id){
    _controller?.close();
    //update invites locally
    if (invites != null){
      List<Incoming>? incoming = invites!.incoming;
      if (incoming != null) {
        List<Incoming> filtered = incoming.where((inc) => inc.sender.id != id).toList();
        invites!.incoming = filtered;
        ref.read(invitesNotifierProvider.notifier).setInvites(invites!);
      }
    }
    FriendsTrackerApi.declineInvite(currentUser?.accessToken, id).then((_) {
      setState(() {
        children = null;
      });
    }).onError((Object error, StackTrace stackTrace){
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not write to database: $error')));
      }
    });
  }

  bool _invitesLoadComplete = false;

  Future<void> getInvites(String accessToken, int userId) async {
    FriendsTrackerApi.getInvites(accessToken, userId).then((invites) {
      setState(() {
        _invitesLoadComplete = true;
      });
      ref.read(invitesNotifierProvider.notifier).setInvites(invites);
    }).onError((Object error, StackTrace stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get invites from database: $error')));
      }
    });
  }

  void buildChildren(Invites invites){
    List<User> awaiting = invites.incoming?.map((item) => User(id: item.sender.id, name: item.sender.name, email: '', avatar: item.sender.avatar, status: Status.awaiting)).toList() ?? [];
    List<Widget> childrenLocal = [];
    for (var user in awaiting) {
      Widget child = MenuItem(user, onCloseCallback, acceptHandler, declineHandler);
      childrenLocal.add(child);
    }
    setState(() {
      children = childrenLocal;
    });
  }

  @override
  void initState() {
    updateInvitesTimer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
        await getInvites(currentUser!.accessToken!, currentUser!.id);
        invites = ref.watch(invitesNotifierProvider);
        if(invites != null) {
          buildChildren(invites!);
        }
    });
    super.initState();
  }

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    updateInvitesTimer?.cancel();
    super.dispose();
  }
  void onCloseCallback() {
    _controller?.close();
  }

  @override
  Widget build(BuildContext context) {
    currentUser = ref.watch(currentUserNotifierProvider);
    invites = ref.watch(invitesNotifierProvider);
    if (!_invitesLoadComplete) {
      getInvites(currentUser!.accessToken!, currentUser!.id);
    }
    if(invites != null) {
      buildChildren(invites!);
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