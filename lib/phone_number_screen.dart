

import 'package:avotek_app/core/util/assets_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class Phonescreen extends StatefulWidget {
  const Phonescreen({super.key});

  @override
  State<Phonescreen> createState() => _PhonescreenState();
}

class _PhonescreenState extends State<Phonescreen> {
  var response1 = const SnackBar(
    content: Text(
      'Done!'
    ) ,
    duration: Duration(seconds: 2),
    );
    var response2 = const SnackBar(
    content: Text(
      'Kindly add your Phone Number!'
    ) ,
    duration: Duration(seconds: 2),
    );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.withOpacity(0.2),
        toolbarHeight: 280,
        leadingWidth: double.infinity,
        leading: Padding(
          padding: const EdgeInsets.only(
            top: 0,right: 16,left: 16,bottom: 16
          ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  const Center(
                      child: Padding(
                        padding: EdgeInsets.only(),
                        child: Text(
                          'Continue with phone',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 51, 50, 50)
                          ),
                           ),
                      ),
                  ),
                const Gap(30),
                  SvgPicture.asset(Asset.video
                    ,height: 160, width: 160),
              ],
            ),
          ),
        ),
        body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Enter Your Phone Number',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(10),
                        TextField(
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.black
                          ),
                          maxLength: 11,
                          showCursor: true,
                          cursorColor: Colors.black,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            suffix: Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: ElevatedButton(  
                              style: ElevatedButton.styleFrom(
                              shape: 
                                const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10)
                                  )
                                ),
                                backgroundColor: const Color.fromARGB(255, 5, 37, 246),
                                minimumSize: const Size(100, 65),
                              ),
                                                        onPressed: (){
                              showDialog(
                                context: context, 
                                builder: (context){
                                  return AlertDialog(
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10)
                                      ),
                                      side: BorderSide(
                                        width: 1,
                                        color: Colors.black
                                      )
                                    ),
                                    title: const Text(
                                      'Are sure you want to continue?'
                                    ),
                                    content: const Text(
                                      'Select any of the options'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: (){
                                          setState(() {
                                            ScaffoldMessenger.of(context).showSnackBar(response2);
                                          });
                                          Navigator.pop(context);
                                        }, 
                                        child: const Text(
                                          'No',
                                          style: TextStyle(
                                            color: Colors.black
                                          ),
                                        )
                                        ),
                                        TextButton(
                                        onPressed: (){
                                          setState(() {
                                            ScaffoldMessenger.of(context).showSnackBar(response1);
                                          });
                                          Navigator.pop(context);
                                        }, 
                                        child: const Text(
                                          'Yes',
                                          style: TextStyle(
                                            color: Colors.black
                                          ),
                                        )
                                        )
                                    ],
                                  );
                                }
                                );
                                                        }, 
                                                        child: const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700
                              ),
                                                        )
                                                        ),
                            ),
                            hintText: 'Phone Number',
                            hintStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20)
                              ),
                              borderSide: BorderSide(
                                width: 2,
                                color: Colors.grey
                              )
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20)
                              ),
                              borderSide: BorderSide(
                                width: 2,
                                color: Colors.grey
                              )
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              );
  }
}