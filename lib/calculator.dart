import 'package:avotek_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  final TextEditingController firstnumber = TextEditingController();
  final TextEditingController secondnumber = TextEditingController();
  num result = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: firstnumber,
                keyboardType: TextInputType.number,
                cursorColor: Colors.black,
                cursorWidth: 1,
                decoration: InputDecoration(
                  labelText: 'First number',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  hintText: 'Enter First number',
                  hintStyle: const TextStyle(
                    fontWeight: FontWeight.normal
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                  ),
                   focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                  ),
                   border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                  ),
                   errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                  )
                ),
              ),
              const Gap(15),
             TextFormField(
              controller: secondnumber,
                keyboardType: TextInputType.number,
                cursorColor: Colors.black,
                cursorWidth: 1,
                decoration: InputDecoration(
                  labelText: 'Second number',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  hintText: 'Enter Second number',
                  hintStyle: const TextStyle(
                    fontWeight: FontWeight.normal
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                  ),
                   focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                  ),
                   border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                  ),
                   errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.blue
                    )
                )),
            ),
             const Gap(70),
             Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 ElevatedButton(
                         style: ButtonStyle(
                            elevation: ButtonStyleButton.allOrNull<double>(0),
                             shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                             RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                            num a = num.parse(firstnumber.text);
                            num b = num.parse(secondnumber.text);
                            setState(() {
                              result = a + b;
                            });
                          },
                          child: Text('Add',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontFamily: Appconstant.fontname,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                          ),
                          ),
                        ),
                        ElevatedButton(
                         style: ButtonStyle(
                            elevation: ButtonStyleButton.allOrNull<double>(0),
                             shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                             RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                             num a = num.parse(firstnumber.text);
                            num b = num.parse(secondnumber.text);
                            setState(() {
                              result = a - b;
                            });
                          },
                          child: Text('Substract',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontFamily: Appconstant.fontname,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                          ),
                          ),
                        ),
                        ElevatedButton(
                         style: ButtonStyle(
                            elevation: ButtonStyleButton.allOrNull<double>(0),
                             shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                             RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                             num a = num.parse(firstnumber.text);
                            num b = num.parse(secondnumber.text);
                            setState(() {
                              result = a * b;
                            });
                          },
                          child: Text('Multiply',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontFamily: Appconstant.fontname,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                          ),
                          ),
                        ),
                        ElevatedButton(
                         style: ButtonStyle(
                            elevation: ButtonStyleButton.allOrNull<double>(0),
                             shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                             RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                             num a = num.parse(firstnumber.text);
                            num b = num.parse(secondnumber.text);
                            setState(() {
                              result = a / b;
                            });
                          },
                          child: Text('Divide',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontFamily: Appconstant.fontname,
                            fontSize: 16,
                            fontWeight: FontWeight.w600
                          ),
                          ),
                        ),
               ],
             ),
             const Gap(20),
             Text('Result: $result.0',
             style: const TextStyle(
                backgroundColor: Color(0XFF3D5CFF),
                color: Color.fromARGB(255, 255, 255, 255),
                height: 2,
             ),
             )
          ]
          ),
        ),
      ),
    );
  }
}