

import 'package:avotek_app/defaults.dart';
import 'package:flutter/material.dart';

class Bottomnavbar extends StatefulWidget {
  const Bottomnavbar({super.key});

  @override
  State<Bottomnavbar> createState() => _BottomnavbarState();
}

class _BottomnavbarState extends State<Bottomnavbar> {
  var indexclicked =0;
  final pages = [
    const Center(
      child: Text(
        'Inbox'
      ),
    ),
     const Center(
      child: Text(
        'Starred'
      ),
    ),
     const Center(
      child: Text(
        'Sent'
      ),
    ),
     const Center(
      child: Text(
        'Draft'
      ),
    ),
     const Center(
      child: Text(
        'Trash'
      ),
    )
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[indexclicked],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue[100],
        type: BottomNavigationBarType.fixed,
        // elevation: 60,
        // selectedItemColor: Defaults.bottomNavItemselectedcolor,
        // unselectedItemColor: Defaults.bottomNavItemcolor,
        currentIndex: indexclicked,
        onTap: (value) {
          setState(() {
            indexclicked = value;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Defaults.bottomNavItemIcon[0]),
          label: Defaults.bottomNavItemText[0]
          ),
          BottomNavigationBarItem(icon: Icon(Defaults.bottomNavItemIcon[1]),
          label: Defaults.bottomNavItemText[1]
          ),
          BottomNavigationBarItem(icon: Icon(Defaults.bottomNavItemIcon[2]),
          label: Defaults.bottomNavItemText[2]
          ),
          BottomNavigationBarItem(icon: Icon(Defaults.bottomNavItemIcon[3]),
          label: Defaults.bottomNavItemText[3]
          ),
          BottomNavigationBarItem(icon: Icon(Defaults.bottomNavItemIcon[4]),
          label: Defaults.bottomNavItemText[4]
          )
        ],
      ),
    );
  }
}