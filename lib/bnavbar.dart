



import 'package:avotek_app/core/util/assets_util.dart';
import 'package:flutter/material.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  GlobalKey<ScaffoldState> drawerkey = GlobalKey();
  String move = 'None clicked';
  var num = 0;
  final pages =[
    const Center(
      child: Text('Inbox'),
    ),
    const Center(
      child: Text('Starred'),
    ),
    const Center(
      child: Text('Sent'),
    ),
    const Center(
      child: Text('Draft'),
    ),
    const Center(
      child: Text('Trash'),
    ),
    const Center(
      child: Text('Cast clicked'),
    ),
    const Center(
      child: Text('Notification clicked'),
    ),
    const Center(
      child: Text('Search clicked'),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: drawerkey,
      endDrawer: const Drawer(),
      appBar: AppBar(
      backgroundColor: Colors.grey,
      leading: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Image(image: AssetImage('assets/image/svgs/notify message icon.svg')),
      ),
      actions: [
        IconButton(
          iconSize: 25,
          onPressed: (){
          setState(() {
            num = 5;
          });
        }, 
        icon: const Icon(Icons.cast)
        ),
        IconButton(
          iconSize: 25,
          onPressed: (){
          setState(() {
            num = 6;
          });
        }, 
        icon: const Icon(Icons.notifications)
        ),
        IconButton(
          iconSize: 25,
          onPressed: (){
          setState(() {
            num = 7;
          });
        }, 
        icon: const Icon(Icons.search)
        ),
        IconButton(
          iconSize: 25,
          onPressed: (){
          setState(() {
            drawerkey.currentState?.openEndDrawer();
          });
        }, 
        icon: CircleAvatar(
          backgroundImage: AssetImage(Asset.hand),
        )
        ),
      ],
      ),
      body: pages[num],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) {
          setState(() {
            num = value;
          });
        },
        type: BottomNavigationBarType.shifting,
        elevation: 60,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black45,
        currentIndex: num,
        iconSize: 25,
        items: 
      const [
        BottomNavigationBarItem(icon: Icon(Icons.inbox),
        label: 'Inbox',
        tooltip: 'Inbox',
        backgroundColor: Colors.green
        ),
        BottomNavigationBarItem(icon: Icon(Icons.star),
        label: 'Starred',
        tooltip: 'Starred',
        backgroundColor: Colors.orange
        ),
        BottomNavigationBarItem(icon: Icon(Icons.send),
        label: 'Sent',
        tooltip: 'Sent',
        backgroundColor: Colors.blue
        ),
        BottomNavigationBarItem(icon: Icon(Icons.drafts),
        label: 'Draft',
        tooltip: 'Drafts',
        backgroundColor: Colors.yellow
        ),
        BottomNavigationBarItem(icon: Icon(Icons.delete),
        label: 'Trash',
        tooltip: 'Trash',
        backgroundColor: Colors.red
        ),
      ]
      
      ),
    );
  }
}