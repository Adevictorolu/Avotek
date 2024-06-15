import 'package:avotek_app/constants.dart';
import 'package:avotek_app/core/util/assets_util.dart';
import 'package:avotek_app/signup_page.dart';
import 'package:avotek_app/splash_screen2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});


  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
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
    Future.delayed(const Duration(seconds: 3),(){
      Navigator.of(context).push(MaterialPageRoute(builder: (_){
        return const Splashscreen2();
      }));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                   onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_){
                  return const Signuppage();
                  }));
                },
                  child: Text('Skip',
                    style: TextStyle(
                      fontFamily: Appconstant.fontname,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey
                    ),
                  ),
                ),
              ),
              SvgPicture.asset(Asset.onboarding,
              height: 200,
              width: 200,
              ),
              const Gap(30),
              Text('Numerous free\n'
                  'trial courses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Appconstant.fontname,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              ),
              Text('Free courses for you to\n'
                  'find your way to learning',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Appconstant.fontname,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
              ),
              const Gap(30),
              SvgPicture.asset(Asset.pavination),
              ]
            ),
          ),
        ),
      ),
    );
  }
}