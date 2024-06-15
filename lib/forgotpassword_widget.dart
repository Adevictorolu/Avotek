import 'package:flutter/material.dart';

class Forgotpassword extends StatelessWidget {
  const Forgotpassword({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: const Align(
        alignment: Alignment.centerRight,
        child: Text('Forgot Password?',
        style: TextStyle(
          decoration: TextDecoration.underline,
          color: Colors.black,
          fontSize: 14,
          fontFamily: 'poppins',
          fontWeight: FontWeight.normal,
        ),
        ),
      ),
    );
  }
}