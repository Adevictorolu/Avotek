import 'package:avotek_app/constants.dart';
import 'package:flutter/material.dart';

class Enterdetailstext extends StatelessWidget {
  const Enterdetailstext({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text('Enter your details below to login',
     style: TextStyle(fontFamily: Appconstant.fontname,
     fontWeight: FontWeight.normal,
     fontSize: 12,
     color: Colors.grey
     )
    );
  }
}
