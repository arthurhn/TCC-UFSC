import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'main.dart';
import 'formPage.dart';
import 'package:flutter/material.dart';
import 'v1_0_fisics_dumper.dart';
import 'geneticAlgorithm.dart';
// import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  Dumper dumper;
  HomePage({Key? key, required this.dumper}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState(dumper);
}


class _HomePageState extends State<HomePage> {
  late Dumper dumper;
  _HomePageState(this.dumper);
  // String massDensity = "";
  // List<double> massOptions = [];
  List<double> freq = [];
  @override
  // Future<void> receiveGeneticAlgorithm() async{
  //   final url = 'http://127.0.0.1:5000/api';
  //   final response = await http.get(Uri.parse(url));
  //
  //   final decoded = json.decode(response.body) as Map<String, dynamic>;
  //
  //   setState((){
  //     massDensity = decoded['massDensity'];
  //     String massOp = decoded['massOp'];
  //     massOp = massOp.replaceAll('[', '');
  //     massOp = massOp.replaceAll(']', '');
  //     massOp = massOp.replaceAll(', ', ' ');
  //     massOptions = (massOp.split(' ')).map(double.parse).toList();
  //   });
  //
  // }
  //
  // Future<void> sendDumper(Dumper _dumper) async{
  //   final url = 'http://127.0.0.1:5000/api';
  //   var map = <String, dynamic>{};
  //   map['massDensity'] = _dumper.massDensity.toString();
  //   final response = await http.post(Uri.parse(url), body: json.encode({"massDensity" : _dumper.massDensity.toString(), "massOp" : _dumper.massOptions}));
  // }


  Widget build(BuildContext context) {

    // sendDumper(dumper);
    // if(dumper.count == 0){
    //   receiveGeneticAlgorithm();
    //   dumper.count++;
    // }

    if(dumper.count == 0){
      // teste da main function
      var aux = parametros([12.0/1000, 7.0/1000, 3.0/1000, 2.0/1000, 2.0/1000], [3.0/1000, 3.0/1000, 3.0/1000, 15.0/1000, 3.0/1000], dumper);
      var rigidez = aux[0];
      var aco = aux[1];
      freq = main_dumper_freq(aco, rigidez, dumper);


      //inicio do algoritmo genetico
      List<Individual> first = generate_new_solution(50, dumper);
      int passou_count = 0;
      int n_passou_count = 0;
      for(int i=0; i<50;i++){
        List<Object> fit = fitness(first[i].aco, first[i].rigidez, [1863, 1470, 1034, 603, 360], dumper);
        if(fit[0] as double == 0.0){
          n_passou_count++;
        }else{
          passou_count++;
        }
      }
      print("passaram: $passou_count, e $n_passou_count não");
      //fim do algoritmo genetico

      dumper.count++;
    }


    return Scaffold(
      body:
      Container(
        decoration: const BoxDecoration(
            color: Color(0xff121220)
        ),
        child: Column(
          children: [
            WindowTitleBarBox(
              child: Row(
                children: [
                  Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Image.asset('images/app_logo4.1.png'),
                        ),
                        IconButton(
                          padding: EdgeInsets.all(5),
                          constraints: BoxConstraints(),
                          icon: Icon(Icons.arrow_back, color: Colors.white,),
                          onPressed: (){
                            setState((){
                              dumper.count = 0;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => FormPage(dumper: dumper,)
                                  ));
                            });
                          },
                        ),
                      ]),
                  Expanded(child: MoveWindow()),
                  const WindowButtons()
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('freq: $freq', style: TextStyle(color: Colors.white),),
              ],
            )
          ]
        ),
      )
    );
  }
}

var buttonColors = WindowButtonColors(
  iconNormal: Colors.white,
  mouseOver: Color(0xff242442),
  // mouseDown: Colors.lightBlue
);
class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors,),
        MaximizeWindowButton(colors: buttonColors,),
        CloseWindowButton(colors: WindowButtonColors(iconNormal: Colors.white, mouseOver: Color(0xff242442), mouseDown: Color(0xffcc0000),)),
      ],
    );
  }
}

