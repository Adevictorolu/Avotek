
import 'package:flutter/material.dart';

class Emailtextfield extends StatelessWidget {
  const Emailtextfield({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: Colors.black,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        focusColor: Colors.blue,
        labelText: 'Email',
        labelStyle: const TextStyle(
          color: Colors.black
        ),
        hintText: ' Enter your email',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
        ),
         focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
      ),
       errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
    ),
     border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
     )
    )
    );
  }
}

class Passwordtextfield extends StatefulWidget {
  const Passwordtextfield({
    super.key,
  });

  @override
  State<Passwordtextfield> createState() => _PasswordtextfieldState();
}

class _PasswordtextfieldState extends State<Passwordtextfield> {
  bool toggle = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: Colors.black,
      keyboardType: TextInputType.visiblePassword,
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Poppins',
      ),
      obscureText: toggle,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: toggle? 
          const Icon(           
            Icons.visibility_off,
            color: Colors.black,
          ):
          const Icon(           
            Icons.visibility,
            color: Colors.black, 
            ),
            onPressed: () { 
            setState(() {
              toggle = !toggle;
            });
           },
        ),
        labelText: 'Password',
        labelStyle: const TextStyle(
          color: Colors.black
        ),
        hintText: ' Enter your password',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
        ),
         focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
      ),
       errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
    ),
     border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            width: 1,
            color: Colors.grey,
          )
     )
    )
    );
  }
}