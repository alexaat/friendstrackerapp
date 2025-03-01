import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/pages/sign_in.dart';

void main() {
  runApp(const ProviderScope(
    child:  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignIn(),
    ),
  ));
}