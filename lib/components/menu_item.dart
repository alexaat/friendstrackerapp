import 'package:flutter/material.dart';
import 'package:friendstrackerapp/models/user.dart';
import 'package:friendstrackerapp/pages/details.dart';

class MenuItem extends StatelessWidget {
  const MenuItem(this.user, this.onCloseCallback, this.acceptHandler, this.declineHandler, {super.key});
  final User user;
  final Function onCloseCallback;
  final Function acceptHandler;
  final Function declineHandler;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onCloseCallback();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => Details(user: user)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        width: MediaQuery.of(context).size.width * 0.8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                user.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () {acceptHandler(user.id);}, icon: const Icon(Icons.check), color: Colors.teal.shade300),
                IconButton(onPressed: () {declineHandler(user.id);}, icon: const Icon(Icons.close), color: Colors.pink.shade300),
              ],
            )
          ],
        ),
      ),
    );
  }
}

