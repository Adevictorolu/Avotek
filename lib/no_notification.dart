

import 'package:avotek_app/core/util/assets_util.dart';
import 'package:avotek_app/no_video_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';


class Notifyscreen extends StatefulWidget {
  const Notifyscreen({super.key});

  @override
  State<Notifyscreen> createState() => _NotifyscreenState();
}

class _NotifyscreenState extends State<Notifyscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            IconButton(
              onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (_){
                  return const Novideoscreen();
                }));
              }, 
              icon: const Icon(
                size: 30,
                Icons.arrow_back
              )
              )
          ],
        ),
      ),
      body: SizedBox(
        height: 416,
        width: 375,
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              SvgPicture.asset(
                height: 160, width: 160,
                Asset.notification),
              const Gap(10),
              const Text(
                'No Notifications yet!',
                style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black
                    ),
              ),
              const Gap(5),
                  const Text(
                      textAlign: TextAlign.center,
                      "We'll notify you once we have\n"
                      "something for you",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
            ]
            ),
      ),
    );
  }
}