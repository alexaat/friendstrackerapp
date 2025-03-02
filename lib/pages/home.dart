import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/api/friends_tracker_api.dart';
import 'package:friendstrackerapp/pages/sign_in.dart';
import 'package:friendstrackerapp/providers/friends_provider.dart';
import 'package:friendstrackerapp/api/google_sign_in_api.dart';
import 'package:friendstrackerapp/components/awaiting_users_menu.dart';
import 'package:friendstrackerapp/models/user.dart';
import 'package:friendstrackerapp/providers/current_user_provider.dart';
import 'package:friendstrackerapp/pages/details.dart';
import 'package:location/location.dart' as flutter_location;
import 'package:friendstrackerapp/models/locations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});
  @override
  ConsumerState<Home> createState() => _HomeState();
}
class _HomeState extends ConsumerState<Home> {
  bool _friendsLoadComplete = false;
  Timer? timer;
  final flutter_location.Location location = flutter_location.Location();
  late bool _serviceEnabled;
  late flutter_location.PermissionStatus _permissionGranted;
  late flutter_location.LocationData _locationData;
  void checkPermissions() async{
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == flutter_location.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != flutter_location.PermissionStatus.granted) {
        return;
      }
    }
  }
  void updateLocation() async {
    _locationData = await location.getLocation();
    if(_locationData.latitude != null && _locationData.longitude != null && currentUser != null){
      if(currentUser!.accessToken != null){
        String lat = _locationData.latitude.toString();
        String lng =  _locationData.longitude.toString();
        Location loc = Location(latitude: lat, longitude: lng, timestamp: '');
        await FriendsTrackerApi.updateLocation(currentUser!.accessToken!, loc);
      }
    }
  }
  User? currentUser;
  bool _searchFieldDisplayed = false;
  final _searchController = TextEditingController();
  List<User> _suggestions = [];
  List<User>? friends;
  Future logout() async {
    setState(() {
      _suggestions = [];
      _searchController.text = '';
      _searchFieldDisplayed = false;
    });
    await GoogleSignInApi.logout();
    if (mounted){
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const SignIn()));
    }
  }
  Future<void> getUsersFromAPI(value) async {
    FriendsTrackerApi.findUsers(currentUser?.accessToken, value)
        .then((users) {
      setState(() {
        _suggestions = users ?? [];
      });
    })
        .onError((Object error, StackTrace stackTrace) {
      print(error);
    });
  }
  void tapHandler(User user) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Details(user: user)));
    setState(() {
      _suggestions = [];
      _searchFieldDisplayed = false;
      _searchController.text = '';
    });
  }
  void deleteHandler(id) {
    FriendsTrackerApi.deleteFriend(currentUser!.accessToken, id);
    setState(() {
      final filtered =  friends!.where((item) => item.id != id).toList();
      ref.read(friendsNotifierProvider.notifier).setFriends(filtered);
      _suggestions = [];
      _searchFieldDisplayed = false;
      _searchController.text = '';
    });
  }
  void getFriends(String? accessToken) async {
    FriendsTrackerApi.getFriends(accessToken).then((friends) {
      setState(() {
        _friendsLoadComplete = true;
      });
      ref.read(friendsNotifierProvider.notifier).setFriends(friends ?? []);
    }).onError((Object error, StackTrace stackTrace){
      print('ERROR: $error');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not fetch friends: $error')));
      }
    });
  }

  void setUpWS() async {
    final wsUrl = Uri.parse(await FriendsTrackerApi.getWSUrl());
    final channel = WebSocketChannel.connect(wsUrl);
    await channel.ready;
    channel.stream.listen((message) {
      //ref.read(friendsNotifierProvider.notifier).setFriends(friends ?? []);
      print('MESSAGE:');
      print(message);
    });

  }

  @override
  Widget build(BuildContext context){

    currentUser = ref.watch(currentUserNotifierProvider);
    if (!_friendsLoadComplete) {
      getFriends(currentUser?.accessToken);
    }
    friends = ref.watch(friendsNotifierProvider);

    checkPermissions();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
              backgroundColor: Colors.teal.shade600,
              title:
              !_searchFieldDisplayed ?
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                        "${currentUser?.name}",
                        overflow: TextOverflow.ellipsis
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: () {
                        setState(() {
                          _searchFieldDisplayed = true;
                        });
                      }, icon: const Icon(Icons.search)),
                      //awaitingUsersMenu ?? const Icon(Icons.notifications),
                      const AwaitingUsersMenu(),
                      IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
                    ],
                  )
                ],
              )
                  :
              Row(
                children: [
                  IconButton(onPressed: () {
                    setState(() {
                      _searchController.text = '';
                      _searchFieldDisplayed = false;
                      _suggestions = [];
                    });
                  }, icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        autocorrect: false,
                        enableSuggestions: false,
                        controller: _searchController,
                        onChanged: getUsersFromAPI,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22.0
                        ),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: 'Search...',
                            hintStyle: TextStyle(fontSize: 20.0, color: Color(0x99000000))
                        ),
                      ),
                    ),
                  ),
                  IconButton(onPressed: () {
                    if( _searchController.text == ''){
                      setState(() {
                        _searchFieldDisplayed = false;
                        _suggestions = [];
                      });
                    } else {
                      _searchController.text = '';
                      _suggestions = [];
                    }
                  }, icon: const Icon(Icons.close))
                ],
              )
          ),
          body: Stack(
            children: [
              if(friends != null)
                Center(
                    child: ListView.builder(
                      itemCount: friends!.length,
                      itemBuilder: (BuildContext context, int index) {
                        final item = friends![index];
                        return Dismissible(
                          key: Key(item.id.toString()),
                          onDismissed: (direction){
                            deleteHandler(item.id);
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('${item.name} is removed from friends list.')));
                          },
                          background: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(Icons.delete),
                            ),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Align(
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.delete),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              final friend = friends![index];
                              final u = User(id: friend.id, name: friend.name, email: friend.email ?? '', avatar: friend.avatar, location: friend.location);
                              tapHandler(u);
                            },
                            child: ListTile(
                              title: Text(friends![index].name),
                            ),
                          ),
                        );
                      },
                    )
                ),
              if(_suggestions.isNotEmpty)
                ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          //int id =  _suggestions[index].id;
                          final friend = _suggestions[index];
                          tapHandler(friend);
                        },
                        child: Container(
                          color: Colors.teal.shade100,
                          child: ListTile(
                            title: Text(_suggestions[index].email),
                          ),
                        ),
                      );
                    }
                )
            ],
          )
      ),
    );
  }
  @override
  void initState() {
    setUpWS();
    _searchController.text = '';
    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) =>  updateLocation());
    super.initState();
  }
  @override
  void dispose() {
    _searchController.dispose();
    timer?.cancel();
    super.dispose();
  }
}