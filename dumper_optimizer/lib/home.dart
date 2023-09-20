import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'main.dart';
import 'formPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'v1_0_fisics_dumper.dart';
import 'geneticAlgorithm.dart';
// import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:core';

const LIMIT_GENERATIONS = 5000;
const GENERATION_SIZE = 1000;
const STATUS_IN_PROCESS = 0;
const STATUS_FINISHED = 1;
const STATUS_ERROR2 = 2; //range de solução muito limitada, não consegue criar individuos válidos o suficiente

class HomePage extends StatefulWidget {
  Dumper dumper;
  HomePage({Key? key, required this.dumper}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState(dumper);
}


class _HomePageState extends State<HomePage> {
  late Dumper dumper;
  _HomePageState(this.dumper);
  late Timer _timer;
  int generation=0;
  DateTime startTime = DateTime.now();
  DateTime currentTime = DateTime.now();
  int currentExecutionTime = 0; //microseconds
  double averageExecutionTime = 0.0;//averageTime (microseconds) for each generation
  List<Individual> rankedsolutions = [];
  List<Individual> crossoversolutions = [];
  int algorithm_status = 0;

  @override
  void initState(){
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {

      // print("len: ${rankedsolutions.length}");
      //inicio do algoritmo genetico

      //condição de parada, seja: o botão de parada, algum erro, seja ele por limite de tempo
      if(generation < LIMIT_GENERATIONS && algorithm_status == STATUS_IN_PROCESS){
        //primeira vez na tela home
        if(rankedsolutions.isEmpty && generation == 0){
          int count = 0;
          print("------------- first gen --------------");
          rankedsolutions = generate_new_solution(GENERATION_SIZE, dumper);
          while(rankedsolutions.isEmpty && count < 1000){
            rankedsolutions = generate_new_solution(GENERATION_SIZE, dumper);
            count++;
          }
          if(count >= 1000){
            algorithm_status = STATUS_ERROR2;
          }
        }

        // print("------------------------------start----------------------------------");
        // print("len ran: ${rankedsolutions.length}");
        // for(int i=0;i<rankedsolutions.length; i++){
        //   print("ran-antes accuracy: ${rankedsolutions[i].accuracy}, weight: ${rankedsolutions[i].weight}");
        //   // print("ran-antes accuracy: ${rankedsolutions[i].accuracy}, weight: ${rankedsolutions[i].weight}, \nrigidez: ${rankedsolutions[i].rigidez}, aco: ${rankedsolutions[i].aco}");
        //
        // }

        setState(() {
          var sel = selection_function(List<Individual>.from(rankedsolutions), dumper.freq, dumper, LIMIT_GENERATIONS, GENERATION_SIZE);
          rankedsolutions = sel[0] as List<Individual>;
          algorithm_status = sel[1] as int;
          List<Individual> clone_ranked = [];
          for(int i=0;i<rankedsolutions.length; i++){
            clone_ranked.add(Individual.from(rankedsolutions[i]));
          }
          crossoversolutions = crossover_function(clone_ranked, dumper);
        });


        // print("len ran: ${rankedsolutions.length}");
        // for(int i=0;i<rankedsolutions.length; i++){
        //   print("ran-depois accuracy: ${rankedsolutions[i].accuracy}, weight: ${rankedsolutions[i].weight}");
        //   // print("ran-depois accuracy: ${rankedsolutions[i].accuracy}, weight: ${rankedsolutions[i].weight}, \nrigidez: ${rankedsolutions[i].rigidez}, aco: ${rankedsolutions[i].aco}");
        // }

        // print("cros len: ${crossoversolutions.length}");
        // for(int i=0;i<crossoversolutions.length; i++){
        //   print("cro- accuracy: ${crossoversolutions[i].accuracy}, weight: ${crossoversolutions[i].weight}");
        // }

        setState(() {
          for(int i=0;i<crossoversolutions.length; i++){
            rankedsolutions.add(Individual.from(crossoversolutions[i]));
          }
        });
        List<Individual> mutation = mutation_function(rankedsolutions, GENERATION_SIZE, dumper);
        setState(() {
          rankedsolutions = [];//erase all population
          for(int i=0;i<mutation.length; i++){
            rankedsolutions.add(Individual.from(mutation[i]));
          }
        });



        //finalizando
        setState(() {
          generation++;
          currentTime = DateTime.now();
          currentExecutionTime = currentTime.difference(startTime).inMicroseconds;
          if(generation != 0){
            averageExecutionTime = currentExecutionTime/generation;
          }
        });
      }
      //fim do algoritmo genetico

    });
  }



  Widget build(BuildContext context) {

    var currentWidth = MediaQuery.of(context).size.width;
    var currentHeight = MediaQuery.of(context).size.height;
    if(dumper.count == 0){
      // teste da main function
      // var aux = parametros([12.0/1000, 7.0/1000, 3.0/1000, 2.0/1000, 2.0/1000], [3.0/1000, 3.0/1000, 3.0/1000, 15.0/1000, 3.0/1000], dumper);
      // var rigidez = aux[0];
      // var aco = aux[1];
      // freq = main_dumper_freq(aco, rigidez, dumper);

      dumper.count++;
    }

    if(currentHeight < 650 || currentWidth < 700){
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              color: Color(0xff121220)
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: Text('The app doesn\'t support these sizes of screen \n width: $currentWidth, height: $currentHeight',
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
          ),
        ),
      );
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Text('Objetivo: ${dumper.freq}', style: TextStyle(color: Colors.white),),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Text(rankedsolutions.isNotEmpty ? 'Melhor resultado: ${rankedsolutions[0].vector_ans}' : 'Melhor resultado: []', style: TextStyle(color: Colors.white),),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(rankedsolutions.isNotEmpty ? 'Erro: ${rankedsolutions[0].vector_errors}' : 'Erro: []', style: TextStyle(color: Colors.white),),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text('Count: $generation', style: TextStyle(color: Colors.white),),
                  ),
                  Column(children: [
                    for(int i=0; i<3;i++)
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(rankedsolutions.length < 3 ? 'Vazio' : 'individual[$i]: accuracy: ${(rankedsolutions[i].accuracy).toStringAsFixed(2)}, weight: ${(rankedsolutions[i].weight).toStringAsFixed(2)} Kg, aco = [${(rankedsolutions[i].aco[0][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[1][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[2][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[3][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[4][2]*1000).toStringAsFixed(1)}]', style: TextStyle(color: Colors.white),),
                      ),
                  ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text('Tempo de execução: ${printTimeFromMicroseconds(currentExecutionTime)}', style: TextStyle(color: Colors.white),),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text('Tempo de execução média de uma geração: ${printTimeFromMicroseconds(averageExecutionTime.toInt())}', style: TextStyle(color: Colors.white),),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text('Status: $algorithm_status', style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            )
          ]
        ),
      )
    );
  }
}

String printTimeFromMicroseconds(int time){
  if(time < 100){
    return "${time.toStringAsFixed(2)}us";
  }else if (time < 100000){
    return "${(time/1000).toStringAsFixed(2)}ms";
  }
  final date = DateTime.fromMicrosecondsSinceEpoch(time);
  String formattedDate = DateFormat('H:m:s').format(date);
  var f = NumberFormat("00", "en_US");
  return "${((time)/(3.6*pow(10, 9))).floor()}h ${f.format(date.minute)}min ${f.format(date.second)}s";
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

