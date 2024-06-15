

import 'package:avotek_app/notificationscreen.dart';
import 'package:flutter/material.dart';

void main(){
 runApp(const Avotek());
}

class Avotek extends StatelessWidget {
  const Avotek ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avotek Mobile App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: const Color.fromRGBO(255, 255, 255, 1),
          secondary: Colors.blue,
          ),
          useMaterial3: true
      ),
      home: const NotificationScreen()
      );
  }
}