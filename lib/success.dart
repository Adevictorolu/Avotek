

import 'package:flutter/material.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  String successful = 'Click the Buttons Now';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: (){
                showDialog(
                  barrierDismissible: false,
                  context: context, 
                  builder: (context){
                  return AlertDialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20)
                      ),
                      side: BorderSide(
                        width: 1,
                        color: Colors.black
                      )
                    ),
                    actions: [
                      TextButton(
                        onPressed: (){
                          setState(() {
                            successful = 'Congratulations';
                          });
                          Navigator.pop(context);
                        }, 
                        child: const Text(
                          'Confirm'
                        )
                        ),
                        TextButton(
                        onPressed: (){
                          setState(() {
                            successful = 'Try again';
                          });
                          Navigator.pop(context);
                        }, 
                        child: const Text(
                          'Unaware'
                        )
                        )
                    ],
                    title: const Text(
                      'Successful'
                    ),
                    content: const Text(
                      'Congratulation\n'
                      'You are now a verified user'
                    ),
                  );
                  }
                  );
              }, 
              child: const Text(
                'Success'
              )
              ),
              Text(
                successful
              )
          ],
        ),
      ),
    );
  }
}