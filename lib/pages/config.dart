import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friendstrackerapp/utils/constants.dart';

class Config extends StatefulWidget {
  const Config({super.key});

  @override
  State<Config> createState() => _ConfigState();
}

class _ConfigState extends State<Config> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  void saveHandler() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(IP, _ipController.text);
    await prefs.setString(PORT, _portController.text);
    if(mounted){
      Navigator.of(context).pop();
    }
  }
  void readPref() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String ip = prefs.getString(IP) ?? defaultIP;
    final String port = prefs.getString(PORT) ?? defaultPort;
    setState(() {
      _ipController.text = ip;
      _portController.text = port;
    });
  }
  @override
  void initState() {
    readPref();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal.shade600,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Config'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 36, right: 36, top: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'IP'),
                autocorrect: false,
                enableSuggestions: false,
                controller: _ipController,
              ),
              const SizedBox(height: 36),
              TextField(
                decoration: const InputDecoration(labelText: 'PORT'),
                autocorrect: false,
                enableSuggestions: false,
                controller: _portController,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                  onPressed: saveHandler,
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
