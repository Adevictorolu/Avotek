

import 'package:avotek_app/core/util/assets_util.dart';
import 'package:avotek_app/no_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class Networkscreen extends StatefulWidget {
  const Networkscreen({super.key});

  @override
  State<Networkscreen> createState() => _NetworkscreenState();
}

class _NetworkscreenState extends State<Networkscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed:(){
             Navigator.of(context).push(MaterialPageRoute(builder: (_){
             return const Notifyscreen();
              }));
              } ,       
         icon: 
            const Icon(
              Icons.arrow_back
               )
                ),
      ),
      body: SizedBox(
        height: 416,
        width: 375,
        child: Center(
          child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(Asset.video
                    ,height: 160, width: 160),
                    const Gap(10),
                    const Text(
                      'No Network!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black
                      ),
                    ),
                    const Gap(5),
                    const Text(
                        textAlign: TextAlign.center,
                        'Please check your internet\n'
                        'connection and try again',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    const Gap(7),
                    ElevatedButton(
                      style: ButtonStyle(
                        fixedSize: ButtonStyleButton.allOrNull<Size>(
                          const Size(240, 50)
                        ),
                        backgroundColor: ButtonStyleButton.allOrNull<Color>(
                          const Color.fromRGBO( 61, 92, 255, 1)
            
                        ),
                        elevation: ButtonStyleButton.allOrNull<double>(
                          0
                        ),
                        shape: ButtonStyleButton.allOrNull<RoundedRectangleBorder>(
                          const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            )
                          )
                        )
                      ),
                      onPressed: (){
                        
                      }, 
                      child: const Text(
                        'Try again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )
                      )
                    ]
                ),
        ),
      ),
    );
  }
}