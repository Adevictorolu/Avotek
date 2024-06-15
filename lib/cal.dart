

import 'package:flutter/material.dart';

class Cal extends StatefulWidget {
  const Cal({super.key});

  @override
  State<Cal> createState() => _CalState();
}

class _CalState extends State<Cal> {
  String expression ='';
  String equation='0';
  String result = '0';
  double resultfs = 48;
  double equationfs = 38;
  buttonpressed(String btnText){
    setState(() {
      if (btnText == 'C') {
        equation = '0';
        result = '0';
      }else if(btnText == 'x'){
        resultfs = 38;
        equationfs = 48;
        equation = equation.substring(0, equation.length -1);
        if (btnText == '') {
          equation = '0';
        }
      }else if(btnText == '='){
        resultfs = 48;
        equationfs = 38;
      }else{
        equationfs = 48;
        resultfs = 38;
        if (equation == '0') {
          equation = btnText;}
          else{
            equation = equation + btnText;
          }
      }
    });
  }
  Widget buildButton(
    String btnText,Color btnColor,double btnHeight,){
      return  Container(
       height: MediaQuery.of(context).size.height *0.1 * btnHeight,
        color: btnColor,
          child: TextButton(
            style: ButtonStyle(
            shape: ButtonStyleButton.allOrNull<OutlinedBorder>(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                   Radius.circular(0)
                     ),
                     side: BorderSide(
                    width: 1,
                   color: Colors.white,
                   style: BorderStyle.solid
                   )
                   ),),
                  ), 
                onPressed: () => buttonpressed(btnText),
                child: Text(
               btnText,
               style: const TextStyle(
             fontSize: 30,
            fontWeight: FontWeight.normal,
             color: Colors.white
            ),
           ),
          ),
       );
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADVANCED CALCULATOR'),
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
            child:  Text(equation, style: TextStyle(fontSize: equationfs),),
          ),
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
            child:  Text(result, style: TextStyle(fontSize: resultfs),),
          ),
          const Expanded(child: 
          Divider()
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Table(
                  children: [
                    TableRow(
                      children: [
                      buildButton('C', Colors.redAccent, 1),
                      buildButton('x', Colors.blue, 1),
                      buildButton('/', Colors.blue, 1)
                      ]
                    ),
                    TableRow(
                      children: [
                      buildButton('7', Colors.black54, 1),
                      buildButton('8', Colors.black54, 1),
                      buildButton('9', Colors.black54, 1)
                      ]
                    ),
                    TableRow(
                      children: [
                      buildButton('4', Colors.black54, 1),
                      buildButton('5', Colors.black54, 1),
                      buildButton('6', Colors.black54, 1)
                      ]
                    ),
                    TableRow(
                      children: [
                      buildButton('1', Colors.black54, 1),
                      buildButton('2', Colors.black54, 1),
                      buildButton('3', Colors.black54, 1)
                      ]
                    ),
                    TableRow(
                      children: [
                      buildButton('.', Colors.black54, 1),
                      buildButton('0', Colors.black54, 1),
                      buildButton('00', Colors.black54, 1)
                      ]
                    )
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.25,
                child: Table(
                  children: [
                    TableRow(
                      children: [
                      buildButton('*', Colors.blue, 1)
                      ]
                    ),
                    TableRow(
                      children: [
                      buildButton('-', Colors.blue, 1)
                      ]
                    ),
                    TableRow(
                      children: [
                      buildButton('+', Colors.blue, 1),
                      ]
                    ),
                    TableRow(
                      children: [
                      buildButton('=', Colors.redAccent, 2)
                      ]
                    ),
                  ])
              )
            ],
          )
        ],
      ),
    );
  }
}