

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  var messages = [
     Container(
       child: Column(
         children: [
           ListTile(
                       shape: const RoundedRectangleBorder(
                       borderRadius: BorderRadius.all(
            Radius.circular(10)
                       )),
                       leading: SvgPicture.asset('assets/image/svgs/notify payment icon.svg'),
                       title: const Text(
            'Bert Pullman', style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: const Text('04:32pm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w200),),
                      subtitle: const Text('Online'),
           ),
           const Text('Congratulation on completing the first lesson keep up the good work',
           textAlign: TextAlign.start,
           style: TextStyle(fontSize: 15, fontWeight: FontWeight.w200),
           )
         ],
       ),
     ),
    const Gap(5),
     ListTile(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10)
          )),
          leading: SvgPicture.asset('assets/image/svgs/notify payment icon.svg'),
          title: const Text(
            'Successful Purchase'
         ),
           subtitle: const Row(
           children: [
            Icon(Icons.access_time),
            Gap(5),
            Text('Just now')
            ],
          )
    ),
    const Gap(5),
     ListTile(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10)
          )),
          leading: SvgPicture.asset('assets/image/svgs/notify payment icon.svg'),
          title: const Text(
            'Successful Purchase'
         ),
           subtitle: const Row(
           children: [
            Icon(Icons.access_time),
            Gap(5),
            Text('Just now')
            ],
          )
    ),
  ];
  var notificatication = [
     ListTile(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10)
          )),
          leading: SvgPicture.asset('assets/image/svgs/notify payment icon.svg'),
          title: const Text(
            'Successful Purchase'
         ),
           subtitle: const Row(
           children: [
            Icon(Icons.access_time),
            Gap(5),
            Text('Just now')
            ],
          )
    ),
    const Gap(5),
     ListTile(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10)
          )),
          leading: SvgPicture.asset('assets/image/svgs/notify message icon.svg'),
          title: const Text(
            'Congratulation on completing the...'
         ),
           subtitle: const Row(
           children: [
            Icon(Icons.access_time),
            Gap(5),
            Text('Just now')
            ],
          ),
          ),
           ListTile(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10)
          )),
          leading: SvgPicture.asset('assets/image/svgs/notify message icon.svg'),
          title: const Text(
            'Your course has been updated, you...'
         ),
           subtitle: const Row(
           children: [
            Icon(Icons.access_time),
            Gap(5),
            Text('Just now')
            ],
          )
          ),
          const Gap(5),
           ListTile(
          shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10)
          )),
          leading:  SvgPicture.asset('assets/image/svgs/notify message icon.svg'),
          title: const Text(
            'Congratulation you have...'
         ),
           subtitle: const Row(
           children: [
            Icon(Icons.access_time),
            Gap(5),
            Text('Just now')
            ],
          )
          ),
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            tabs: [
            Tab(child: Text('Message', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),),
            Tab(child: Text('Notification', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),)
          ]),
          title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.black, fontSize: 34, fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return messages[index];
              },
            ),
            ListView.builder(
              itemCount: notificatication.length,
              itemBuilder: (context, index) {
                return notificatication[index];
              },
            )
        ]),
      ),
    );
  }
}