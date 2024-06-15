
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Practice extends StatefulWidget {
  const Practice({super.key});

  @override
  State<Practice> createState() => _PracticeState();
}

class _PracticeState extends State<Practice> {
  final TextEditingController first = TextEditingController();
  final TextEditingController second = TextEditingController();
  num result = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Center(
        child: Column(
          children: [
            Field1(first: first),
            Field2(second: second),
            const Gap(30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                     shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                             RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              )
                               ),
                    backgroundColor: ButtonStyleButton.allOrNull<Color>(
                      Colors.green
                    ),
                    elevation: ButtonStyleButton.allOrNull<double>(
                      0
                    ),
                    fixedSize: ButtonStyleButton.allOrNull<Size>(
                      const Size(160, 50)
                    )
                  ),
                  onPressed: (){
                     num a = num.parse(first.text);
                     num b = num.parse(second.text);
                    setState(() {
                     result = a+b;
                    });
                  }, 
                  child: const Text(
                    'Addition',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16
                    ),
                  )
                  ),
                  ElevatedButton(
                  style: ButtonStyle(
                     shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                             RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              )
                               ),
                    backgroundColor: ButtonStyleButton.allOrNull<Color>(
                      Colors.green
                    ),
                    elevation: ButtonStyleButton.allOrNull<double>(
                      0
                    ),
                    fixedSize: ButtonStyleButton.allOrNull<Size>(
                      const Size(160, 50)
                    )
                  ),
                  onPressed: (){
                     num a = num.parse(first.text);
                     num b = num.parse(second.text);
                    setState(() {
                     result = a-b;
                    });
                  }, 
                  child: const Text(
                    'Substraction',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16
                    ),
                  )
                  ),
                  ElevatedButton(
                  style: ButtonStyle(
                     shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                             RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              )
                               ),
                    backgroundColor: ButtonStyleButton.allOrNull<Color>(
                      const Color.fromARGB(255, 32, 155, 114)
                    ),
                    elevation: ButtonStyleButton.allOrNull<double>(
                      0
                    ),
                    fixedSize: ButtonStyleButton.allOrNull<Size>(
                      const Size(160, 50)
                    )
                  ),
                  onPressed: (){
                     num a = num.parse(first.text);
                     num b = num.parse(second.text);
                    setState(() {
                     result = a*b;
                    });
                  }, 
                  child: const Text(
                    'Multiplication',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16
                    ),
                  )
                  ),
                  ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: ButtonStyleButton.allOrNull<Color>(
                      Colors.green
                    ),
                    elevation: ButtonStyleButton.allOrNull<double>(
                      0
                    ),
                    fixedSize: ButtonStyleButton.allOrNull<Size>(
                      const Size(160, 50)
                    )
                  ),
                  onPressed: (){
                     num a = num.parse(first.text);
                     num b = num.parse(second.text);
                    setState(() {
                     result = a/b;
                    });
                  }, 
                  child: const Text(
                    'Division',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16
                    ),
                  )
                  )
              ],
            ),
            const Gap(30),
            Container(
              width: 150,
              height: 75,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.only(
                 topLeft: Radius.circular(50),
                 bottomRight: Radius.circular(50)
                ) 
              ),
              child: Text(
                'Result = $result',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            )
        ],
        ),
      ),
    );
  }
}

class Field2 extends StatelessWidget {
  const Field2({
    super.key,
    required this.second,
  });

  final TextEditingController second;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: second,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            label: Text(
              'Enter Second Number',
              style: TextStyle(
    fontWeight: FontWeight.bold
              ),
            ),
            hintText: 'Second Number',
            hintStyle: TextStyle(
              fontWeight: FontWeight.w700
            ),
            labelStyle: TextStyle(
              color: Colors.blue
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
    Radius.circular(40)
              ),
              borderSide: BorderSide(
    width: 1,
    color: Colors.purple
              )
            ),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
    Radius.circular(40)
              ),
              borderSide: BorderSide(
    width: 1,
    color: Colors.purple
              ),
          ),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
    Radius.circular(40)
              ),
              borderSide: BorderSide(
    width: 1,
    color: Colors.purple
              )
          ),
          )
        );
  }
}

class Field1 extends StatelessWidget {
  const Field1({
    super.key,
    required this.first
  });
  final TextEditingController first;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: first,
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        label: Text(
          'Enter First Number',
          style: TextStyle(
            fontWeight: FontWeight.bold
          ),
        ),
        hintText: 'First Number',
        hintStyle: TextStyle(
          fontWeight: FontWeight.w700
        ),
        labelStyle: TextStyle(
          color: Colors.blue
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(40)
          ),
          borderSide: BorderSide(
            width: 1,
            color: Colors.purple
          )
        ),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(40)
          ),
          borderSide: BorderSide(
            width: 1,
            color: Colors.purple
          ),
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(40)
          ),
          borderSide: BorderSide(
            width: 1,
            color: Colors.purple
          )
      ),
      )
    );
  }
}