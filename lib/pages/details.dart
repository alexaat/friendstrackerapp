import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/api/friends_tracker_api.dart';
import 'package:friendstrackerapp/providers/invites_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:friendstrackerapp/providers/current_user_provider.dart';
import 'package:friendstrackerapp/utils/geocode.dart';
import 'package:friendstrackerapp/components/avatar.dart';
import 'package:friendstrackerapp/models/invites.dart';
import 'package:friendstrackerapp/models/user.dart';
import 'package:friendstrackerapp/providers/friends_provider.dart';
import 'package:friendstrackerapp/pages/map.dart' as location_map;

import '../utils/time.dart';

class Details extends ConsumerStatefulWidget {
  const Details({super.key, required this.user});
  final User user;
  @override
  ConsumerState<Details> createState() => _DetailsState();
}
class _DetailsState extends ConsumerState<Details> {
  User? currentUser;
  User? user;
  bool _dataLoading = true;

  List<User>? friends;
  Future findUser(String accessToken, int id) async {
    try {
      User? u = await FriendsTrackerApi.findUser(accessToken, id);
      setState(() {
        _dataLoading = false;
      });

      if (u == null) {
        user = null;
        return;
      }

      u.status = Status.free;
      List<User> list = friends?.where((friend) => friend.id == u.id)
          .toList() ?? [];
      if (list.isNotEmpty) {
        u.status = Status.approved;
        u.location = list[0].location;
      } else {
        // check that waiting approval by current user (incoming)
        Invites? invites = ref.watch(invitesNotifierProvider);
        List<Incoming> filtered = invites?.incoming?.where((item) => item.sender.id == u.id)
            .toList() ?? [];
        if (filtered.isNotEmpty) {
          u.status = Status.awaiting;
        } else {
          // check that current user waiting approval by user (outgoing)
          List<Outgoing> filtered = invites?.outgoing?.where((item) =>
          item.recipient.id == u.id).toList() ?? [];
          if (filtered.isNotEmpty) {
            u.status = Status.pending;
          }
        }
      }
      if(u.location == null) {
        setState(() {
          user = u;
        });
      } else {
        GeoCode.coordinatesToPlace(double.parse(u.location!.latitude), double.parse(u.location!.longitude), (Placemark placeMark) {
          if(mounted){
            setState(() {
              String place = GeoCode.parsePlace(placeMark);
              u.location?.title = place;
              user = u;
            });
          }
        });
      }
    } catch (error){
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not fetch friends: $error')));
      }
    }
  }
  void inviteHandler() async{
      setState(() {
        user?.status = Status.pending;
      });
      await FriendsTrackerApi.sendInvite(currentUser?.accessToken, user?.id);
  }
  void acceptHandler() async {
      Invites? invites = ref.watch(invitesNotifierProvider);
      if (invites != null){
        List<Incoming>? incoming = invites.incoming;
        if (incoming != null && incoming.isNotEmpty){
          // update friends list locally
          List<Incoming> incomingFriend = incoming.where((inc) =>  inc.sender.id == user?.id).toList();
          Person sender = incomingFriend[0].sender;
          User friend = User(id: sender.id, name: sender.name, email: '');
          List<User> friends = ref.watch(friendsNotifierProvider);
          friends.add(friend);
          ref.read(friendsNotifierProvider.notifier).setFriends(friends);
          // update invites list locally
          List<Incoming> filtered = incoming.where((inc) => inc.sender.id != user?.id).toList();
          invites.incoming = filtered;
          ref.read(invitesNotifierProvider.notifier).setInvites(invites);
        }
        //update user locally
        setState(() {
          user?.status = Status.approved;
        });
      }
      //update remotely
      await FriendsTrackerApi.acceptInvite(currentUser?.accessToken, user?.id);
      List<User>? list = await FriendsTrackerApi.getFriends(currentUser?.accessToken);
      ref.read(friendsNotifierProvider.notifier).setFriends(list ?? []);
      //update local with details
      if (list != null && list.isNotEmpty){
        List<User> friendsList = list.where((u) => u.id == user?.id).toList();
        if(friendsList .isNotEmpty){
          User friend = friendsList[0];
          setState(() {
            user = friend;
            user?.status = Status.approved;
          });
        }
      }
  }
  void declineHandler() async {
      //update invites locally
      Invites? invites = ref.watch(invitesNotifierProvider);
      if (invites != null){
        List<Incoming>? incoming = invites.incoming;
        if (incoming != null) {
          List<Incoming> filtered = incoming.where((inc) => inc.sender.id != user?.id).toList();
          invites.incoming = filtered;
          ref.read(invitesNotifierProvider.notifier).setInvites(invites);
        }
      }
      //update user list locally
      setState(() {
        user!.status = Status.free;
      });
      // update remote
      await FriendsTrackerApi.declineInvite(currentUser?.accessToken, user?.id);
  }
  void showMapHandler() {
    final friend = User(id: user!.id, name: user!.name, email: user!.email, location: user!.location);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => location_map.Map(friend)));
  }

  @override
  Widget build(BuildContext context) {
    currentUser = ref.watch(currentUserNotifierProvider);
    friends = ref.watch(friendsNotifierProvider);
    if (currentUser != null && currentUser?.accessToken != null){
      if(user == null){
        findUser(currentUser!.accessToken!, widget.user.id);
      }
    }
    var backgroundColor = Colors.white;
    switch (user?.status) {
      case Status.free:
        backgroundColor = Colors.white;
        break;
      case Status.approved:
        backgroundColor = const Color(0xFFE0F7FA);
        break;
      case Status.awaiting:
        backgroundColor = const Color(0xFFE6E6FA);
        break;
      case Status.pending:
        backgroundColor = const Color(0xFFFFCC99);
        break;
      case null:
        break;
    }
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor:backgroundColor,
            appBar: AppBar(
                backgroundColor: Colors.teal.shade600,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(user?.name ?? widget.user.name)
            ),
            body: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 36.0, vertical: 36.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 150),
                  Avatar(user: user ?? widget.user),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? widget.user.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    )),
                  const SizedBox(height: 16),
                  _dataLoading ?
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.teal),
                    )
                  :
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if(user?.status == Status.pending)
                          const Text('Pending Approval'),
                        if(user?.status == Status.awaiting)
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(onPressed: acceptHandler, icon: Icon(Icons.check, color: Colors.teal.shade300)),
                                const SizedBox(width: 16),
                                IconButton(onPressed: declineHandler, icon: Icon(Icons.close, color: Colors.pink.shade300)),
                              ]
                          ),
                        if(user?.status == Status.approved)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                  'Location',
                                  style: TextStyle(fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 8),
                              Text(user?.location == null ? 'Unknown' :'${user?.location?.latitude}, ${user?.location?.latitude}'),
                              if(user?.location != null)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if(user?.location?.title != null)
                                      const SizedBox(height: 8),
                                    if(user?.location?.title != null)
                                      Text(
                                          '${user?.location?.title}',
                                          textAlign: TextAlign.center,
                                          softWrap: true,


                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Updated: ',  style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(Time.timeToPeriod(user?.location?.timestamp)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    IconButton(onPressed: () {
                                      if(user!=null && user?.location != null){
                                        showMapHandler();
                                      }
                                    }, icon: const Icon(Icons.map))
                                  ],
                                )
                            ],
                          ),
                        if(user?.status == Status.free)
                          ElevatedButton.icon(
                              onPressed: inviteHandler,
                              label: const Text(
                                'Invite',
                                style: TextStyle(
                                    color: Colors.teal
                                ),
                              ),
                              icon: const Icon(
                                  Icons.person_add,
                                  color: Colors.teal
                              ))
                      ]
                  )
                ],
              ),
            )
        )
    );
  }
}