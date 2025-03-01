import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/pages/config.dart';
import 'package:friendstrackerapp/api/google_sign_in_api.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:friendstrackerapp/api/friends_tracker_api.dart';
import 'package:friendstrackerapp/pages/home.dart';
import 'package:friendstrackerapp/providers/current_user_provider.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {

  Future signIn() async {
    final googleUser = await GoogleSignInApi.login();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    if(googleUser == null || googleAuth == null || accessToken == null){
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in failed')));
      }
    }else {
      FriendsTrackerApi.authenticate(accessToken).then((user){
        user.accessToken = accessToken;
        ref.read(currentUserNotifierProvider.notifier).setCurrentUser(user);
          if(mounted){
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const Home()));
          }
        // KaquizApi.getFriends(accessToken)
        //     .then((friends) {
        //   ref.read(friendsNotifierProvider.notifier).setFriends(friends ?? []);
        //   if(mounted){
        //     Navigator.of(context).pushReplacement(MaterialPageRoute(
        //         builder: (context) => const Home()));
        //   }
        // })
        //     .onError((Object error, StackTrace stackTrace){
        //   print('ERROR: $error');
        //   if(mounted) {
        //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign in failed: $error')));
        //   }
        // });
      }).onError((Object error, StackTrace stackTrace){
        print('ERROR: $error');
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign in failed: $error')));
        }
      });
    }
  }


  void configHandler() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const Config()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.teal.shade600,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Friends Tracker'),
              IconButton(onPressed: configHandler, icon: const Icon(Icons.settings)),
            ],
          )
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: const Text(
                  'Welcome to Friends Tracker App',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                  onPressed: signIn,
                  child: const Text(
                      'Sign In with Google',
                      style: TextStyle(color: Colors.black, fontSize: 16)
                  )),
            ],
          )
      ),
    );
  }
}
