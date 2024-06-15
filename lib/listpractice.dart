

import 'package:flutter/material.dart';

void main(){
  var buy = [
    const ListTile(
      leading: Text('J', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),),
      title: Text('Ademola victor Oluokun'),
      subtitle: Text('I stand for GOD gallantly'),
      trailing: Text('JESUS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),),
    ),
    const ListTile(
      leading: Text('J', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),),
      title: Text('Ademola victor Oluokun'),
      subtitle: Text('I stand for GOD gallantly'),
      trailing: Text('JESUS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),),
    ),
    const ListTile(
      leading: Text('J', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),),
      title: Text('Ademola victor Oluokun'),
      subtitle: Text('I stand for GOD gallantly'),
      trailing: Text('JESUS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),),
    ),
    const ListTile(
      leading: Text('J', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),),
      title: Text('Ademola victor Oluokun'),
      subtitle: Text('I stand for GOD gallantly'),
      trailing: Text('JESUS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),),
    ),
    const ListTile(
      leading: Text('J', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),),
      title: Text('Ademola victor Oluokun'),
      subtitle: Text('I stand for GOD gallantly'),
      trailing: Text('JESUS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),),
    ),
    const ListTile(
      leading: Text('J', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),),
      title: Text('Ademola victor Oluokun'),
      subtitle: Text('I stand for GOD gallantly'),
      trailing: Text('JESUS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),),
    )
  ];

  runApp(MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: buy.length,
              itemBuilder: (context, index) {
                return buy[index];
              },
              ),
          )
        ],
      ),
    ),
  ));
}