
import 'package:avotek_app/constants.dart';
import 'package:avotek_app/login_page.dart';
import 'package:avotek_app/text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  bool checkbox = true;
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
              Text('Sign Up',
                style: TextStyle(fontFamily: Appconstant.fontname,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: Colors.black
                )
              ),
              const Gap(5),
               const Enterdetailstext2()
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
            const Gap(30),
            const Signupbutton(),
            const Gap(20),
            Row(
              children: [
                IconButton(
                 icon: checkbox?
            
              const Icon(           
              Icons.check_box_outline_blank,
              color: Colors.black,
              ):
              const Icon(           
              Icons.check_box,
              color: Color(0XFF3D5CFF), 
              ),
              onPressed: () { 
              setState(() {
              checkbox = !checkbox;
                });
                },),
                const Gap(1),
                Text('By creating an account you have to agree with our terms & condition.',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontFamily: Appconstant.fontname,
                ),
                )
              ],
            ),
            const Gap(20),
            Spantext(onpressed: () { 
              Navigator.of(context).push(MaterialPageRoute(builder: (_){
                return const Loginpage();
              }));
             },)
          ],
        ),
      ),
    );
  }
}

class Spantext extends StatelessWidget {
  final VoidCallback? onpressed;
  const Spantext({
    super.key, required this.onpressed
  });

  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(
      text: 'Already have an account?',
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
          text: 'Log in',
          style: TextStyle(
            decoration: TextDecoration.underline,
            color: Colors.blue[900],
            fontWeight: FontWeight.w500,
          )
        ),
      ]
    ));
  }
}
class Enterdetailstext2 extends StatelessWidget {
  const Enterdetailstext2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text('Enter your details below & free sign up',
     style: TextStyle(fontFamily: Appconstant.fontname,
     fontWeight: FontWeight.normal,
     fontSize: 12,
     color: Colors.grey
     )
    );
  }
}
class Signupbutton extends StatelessWidget {
  const Signupbutton({
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
      Text('Create Account',
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