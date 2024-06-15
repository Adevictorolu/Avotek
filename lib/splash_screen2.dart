import 'package:avotek_app/constants.dart';
import 'package:avotek_app/core/util/assets_util.dart';
import 'package:avotek_app/signup_page.dart';
import 'package:avotek_app/splash_screen3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class Splashscreen2 extends StatefulWidget {
  const Splashscreen2 ({super.key});

  @override
  State<Splashscreen2> createState() => _Splashscreen2State();
}

class _Splashscreen2State extends State<Splashscreen2> {
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
        return const Splashscreen3();
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
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_){
                  return const Signuppage();
                  }));
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Skip',
                    style: TextStyle(
                      fontFamily: Appconstant.fontname,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey
                    ),
                  ),
                ),
              ),
              SvgPicture.asset(Asset.onboarding2,
              height: 200,
              width: 200,
              ),
              const Gap(30),
              Text('Quick and easy\n'
              'Learning',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Appconstant.fontname,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              ),
              Text('Easy and fast learning at\n'
                  'anytime to help you\n'
                  'improve various skills',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Appconstant.fontname,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
              ),
              const Gap(30),
              SvgPicture.asset(Asset.pavination2),
              ]
            ),
          ),
        ),
      ),
    );
  }
}