import 'package:avotek_app/constants.dart';
import 'package:avotek_app/core/util/assets_util.dart';
import 'package:avotek_app/enterdetails_widget.dart';
import 'package:avotek_app/forgotpassword_widget.dart';
import 'package:avotek_app/signup_page.dart';
import 'package:avotek_app/text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class Loginpage extends StatelessWidget {
  const Loginpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.withOpacity(0.2),
        toolbarHeight: 120,
        leadingWidth: double.infinity,
        leading: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Login',
                style: TextStyle(fontFamily: Appconstant.fontname,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: Colors.black
                )
              ),
              const Gap(5),
               const Enterdetailstext()
            ],
          ),
        ),
      ),
      body:   Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Gap(20),
            const Emailtextfield(),
            const Gap(30),
            const Passwordtextfield(),
            const Gap(10),
            const Forgotpassword(),
            const Gap(30),
            const Loginbutton(),
            const Gap(20),
            Spantext(
              title: "Don't have an account?",
              option: 'SignUp',
              onpressed: () { 
              Navigator.of(context).push(MaterialPageRoute(builder: (_){
                return const Signuppage();
              }));
             },),
            const Gap(30),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: 
                Divider(
                  color: Colors.grey,
                )
                ),
                Gap(15),
                Text(
                  'Or login with'
                ),
                Gap(15),
                Expanded(child: 
                Divider(
                  color: Colors.grey,
                )
                )
              ],
            ),
            const Gap(20),
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(Asset.goggle),
              const Gap(30),
              SvgPicture.asset(Asset.facebook)
            ],
            )
          ],
        ),
      ),
    );
  }
}

class Spantext extends StatelessWidget {
  final VoidCallback? onpressed;
  final String title;
  final String option;
  const Spantext({
    super.key, required this.onpressed,
    required this.option, required this.title
  });

  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(
      text: title,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.normal,
        fontFamily: Appconstant.fontname,
    
      ),
      children: [
        TextSpan(
          recognizer: TapGestureRecognizer()..onTap = (){
            onpressed?.call();
          },
          text: option,
          style: TextStyle(
            color: Colors.blue[900],
            fontWeight: FontWeight.w500,
          )
        ),
      ]
    ));
  }
}

class Loginbutton extends StatelessWidget {
  const Loginbutton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: (){
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_){
      //   return const Appscreen();
      // }));
    },
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
        Size(MediaQuery.of(context).size.width, 50)
      )
    ),
     child: 
      Text('Log in',
      style: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontFamily: Appconstant.fontname,
      fontWeight: FontWeight.w600,
       ),
      ),
    );
  }
}