import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:friendstrackerapp/models/user.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.user});
  final User? user;
  final radius = 90.0;
  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.bold,
        color: Colors.teal.shade600
    );
    if(user == null){
      return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    blurRadius: 1,
                    color: Colors.grey.shade300,
                    spreadRadius: 1)
              ],
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundImage: null,
              backgroundColor: Colors.white
            )
        );
    }
    //get initials
    String initials = '';
    List<String>? split = user?.name.split(' ');
    if(split != null) {
      var filtered = split.where((element) => element.trim()!='').toList();
      if(filtered.isNotEmpty){
        initials = filtered[0][0].toUpperCase();
      }
      if(filtered.length > 1){
        initials += ' ${filtered[1][0].toUpperCase()}';
      }
    }
    if(user!.avatar == null){
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                blurRadius: 1,
                color: Colors.grey.shade300,
                spreadRadius: 1)
          ],
        ),
        child:
          CircleAvatar(
          radius: radius,
          backgroundImage: null,
          backgroundColor: Colors.white,
          child: Text(initials, style: textStyle)
        )
      );
    }
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                blurRadius: 1,
                color: Colors.grey.shade300,
                spreadRadius: 1)
          ],
        ),
        child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: CachedNetworkImage(
              imageUrl: user!.avatar!,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(radius)),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Text(initials, style: textStyle),
            )
        )
      );
  }
}