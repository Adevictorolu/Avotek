

import 'package:avotek_app/constants.dart';
import 'package:avotek_app/core/util/assets_util.dart';
import 'package:avotek_app/login_page.dart';
import 'package:avotek_app/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class Splashscreen3 extends StatefulWidget {
  const Splashscreen3({super.key});

  @override
  State<Splashscreen3> createState() => _Splashscreen3State();
}

class _Splashscreen3State extends State<Splashscreen3> {
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
                const Gap(50),
              SvgPicture.asset(Asset.onboarding3,
              height: 200,
              width: 200,
              ),
              const Gap(30),
              Text('Create your own\n'
              'study plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Appconstant.fontname,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              ),
              Text('Study according to the\n'
              'study plan,make study\n'
              'more motivated',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Appconstant.fontname,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
              ),
              const Gap(30),
              SvgPicture.asset(Asset.pavination3),
              const Gap(70),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     ElevatedButton(
                    style: ButtonStyle(
                      elevation: ButtonStyleButton.allOrNull<double>(0),
                       shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                       RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                        )
                         ),
                      backgroundColor: ButtonStyleButton.allOrNull<Color>(
                         const Color(0XFF3D5CFF)
                      ),
                       fixedSize: ButtonStyleButton.allOrNull<Size>(
                         const Size(160, 50)
                       )
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_){
                        return const Signuppage();
                      }));
                    },
                    child: Text('Sign up',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: Appconstant.fontname,
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                    ),
                    ),
                  ),
                  const Gap(15),
                    ElevatedButton(
                     style: ButtonStyle(
                        elevation: ButtonStyleButton.allOrNull<double>(0),
                         shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                         RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            width: 1,
                            color:  Color(0XFF3D5CFF),
                          )
                          )
                           ),
                        backgroundColor: ButtonStyleButton.allOrNull<Color>(
                           const Color.fromARGB(255, 255, 255, 255)
                        ),
                         fixedSize: ButtonStyleButton.allOrNull<Size>(
                           const Size(160, 50)
                         )
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_){
                          return const Loginpage();
                        }));
                      },
                      child: Text('Log in',
                      style: TextStyle(
                        color: const Color(0XFF3D5CFF),
                        fontFamily: Appconstant.fontname,
                        fontSize: 16,
                        fontWeight: FontWeight.w600
                      ),
                      ),
                    ),
                  ],
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}