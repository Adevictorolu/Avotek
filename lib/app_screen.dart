import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:avotek_app/constants.dart';
import 'package:avotek_app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Appscreen extends StatefulWidget {
  const Appscreen({super.key});

  @override
  State<Appscreen> createState() => _AppscreenState();
}

class _AppscreenState extends State<Appscreen> {
  @override
  void initState() {
    loaddelay();
    super.initState();
  }

  @override
  void dispose() {
    
    super.dispose();
  }

  void loaddelay(){
    Future.delayed(const Duration(seconds: 5),(){
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_){
        return const Splashscreen();
      }));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedTextKit(
              animatedTexts: [WavyAnimatedText(
                'Avotek App',
                textStyle: TextStyle(
                color: Colors.white,
                fontFamily: Appconstant.fontname,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
              speed: const Duration(milliseconds: 150)
              )],
              totalRepeatCount: 2,
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
              ),
            const Gap(10),
               AnimatedTextKit(animatedTexts: [
                FadeAnimatedText(
              'Learning through video course',
              textStyle: TextStyle(fontFamily: Appconstant.fontname,
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: Colors.white
                ),
                duration: const Duration(seconds: 4)
                )
               ],
                totalRepeatCount: 1,
               )
          ],
        ),
      ),
    );
  }
}