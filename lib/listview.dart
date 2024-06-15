

// import 'package:flutter/material.dart';

// class Listview extends StatefulWidget {
//   const Listview({super.key});

//   @override
//   State<Listview> createState() => _ListviewState();
// }

// class _ListviewState extends State<Listview> {
//    Widget road1(String name, String fullname, String subtitle, String trailing){
//    return Container(
//       color: Colors.black54,
//       height: MediaQuery.of(context).size.height * .25,
//       width: double.infinity,
//       child: Row(
//         children: [
//           Text(name, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),),
//           Column(
//             children: [
//               Text(fullname),
//               Text(subtitle)
//             ],
//           ),
//           Text(trailing, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),)
//         ],
//       ),
//       );}
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           road1('A', 'Ademola Victor', 'I stand for GOD', 'Invincible'),
//           road1('A', 'Ademola Victor', 'I stand for GOD', 'Invincible'),
//           road1('A', 'Ademola Victor', 'I stand for GOD', 'Invincible'),
//           road1('A', 'Ademola Victor', 'I stand for GOD', 'Invincible'),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class Listview1 extends StatefulWidget {
  const Listview1({super.key});

  @override
  State<Listview1> createState() => _Listview1State();
}

class _Listview1State extends State<Listview1> {
   Widget road1(String name, String fullname, String subtitle, String trailing){
   return Padding(
     padding: const EdgeInsets.all(2.0),
     child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(20)
          ),
          side: BorderSide(
            width: 0.5,
            color: Colors.blue
          )
        ),
        leading: Text(
          name, style: const TextStyle(
            fontSize: 40, fontWeight: FontWeight.w800
          ),
        ),
        title: Text(
          fullname
        ),
        subtitle: Text(
          subtitle
        ),
        trailing: Text(
          trailing
        ),
      ),
   );
      }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          road1('A', 'Ademola Victor', 'I stand for GOD', 'Invincible'),
          road1('J', 'John Samuel', 'Raisng a Sound', 'Invincible'),
          road1('M', 'Marvelous Prince', 'I can do all things', 'Invincible'),
          road1('G', 'Goodness Paul', 'Everything is possible with GOD', 'Invincible'),
        ],
      ),
    );
  }
}
