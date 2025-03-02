import 'package:flutter/material.dart';

import '../models/user.dart';

class Details extends StatefulWidget {
  const Details({super.key, required this.user});

  final User user;

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
