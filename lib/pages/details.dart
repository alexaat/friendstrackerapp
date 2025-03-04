import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/api/friends_tracker_api.dart';
import 'package:geocoding/geocoding.dart';
import 'package:friendstrackerapp/providers/current_user_provider.dart';
import 'package:friendstrackerapp/utils/geocode.dart';
import 'package:friendstrackerapp/components/avatar.dart';
import 'package:friendstrackerapp/models/invites.dart';
import 'package:friendstrackerapp/models/user.dart';
import 'package:friendstrackerapp/providers/friends_provider.dart';
import 'package:friendstrackerapp/pages/map.dart' as location_map;

class Details extends ConsumerStatefulWidget {
  const Details({super.key, required this.user});
  final User user;
  @override
  ConsumerState<Details> createState() => _DetailsState();
}
class _DetailsState extends ConsumerState<Details> {
  User? currentUser;
  User? user;

  List<User>? friends;
  Future findUser(String accessToken, int id) async {
    try {
      User? u = await FriendsTrackerApi.findUser(accessToken, id);
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
        //2. check that waiting approval by current user (incoming)
        Invites invites = await FriendsTrackerApi.getInvites(
            accessToken, currentUser?.id);
        List<Incoming> filtered = invites.incoming?.where((item) => item.sender.id == u.id)
            .toList() ?? [];
        if (filtered.isNotEmpty) {
          u.status = Status.awaiting;
        } else {
          //3. check that current user waiting approval by user (outgoing)
          List<Outgoing> filtered = invites.outgoing?.where((item) =>
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
    if(user != null && currentUser != null){
      await FriendsTrackerApi.sendInvite(currentUser!.accessToken, user!.id);
      setState(() {
        user = null;
      });
    }
  }
  void acceptHandler() async {
    if(user != null && currentUser != null){
      await FriendsTrackerApi.acceptInvite(currentUser!.accessToken, user!.id);
      List<User>? list = await FriendsTrackerApi.getFriends(currentUser!.accessToken);
      setState(() {
        ref.read(friendsNotifierProvider.notifier).setFriends(list ?? []);
        user = null;
      });
    }
  }
  void declineHandler() async {
    if(user != null && currentUser != null){
      await FriendsTrackerApi.declineInvite(currentUser!.accessToken, user!.id);
      setState(() {
        user = null;
      });
    }
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
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 150),
                  Avatar(user: user ?? widget.user),
                  const SizedBox(height: 16),
                  Text(user?.name ?? widget.user.name),
                  const SizedBox(height: 16),
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
                        const Text('Location'),
                        const SizedBox(height: 8),
                        Text(user?.location == null ? 'Unknown' :'${user?.location?.latitude}, ${user?.location?.latitude}'),
                        if(user?.location != null)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if(user?.location?.title != null)
                                const SizedBox(height: 8),
                              if(user?.location?.title != null)
                                Text('${user?.location?.title}'),
                              const SizedBox(height: 8),
                              const Text('Updated'),
                              const SizedBox(height: 8),
                              Text('${user?.location?.timestamp}'),
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
                ],
              ),
            )
        )
    );
  }
}