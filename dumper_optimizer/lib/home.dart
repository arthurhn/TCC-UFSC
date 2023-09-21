import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/scheduler.dart';
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

const LIMIT_GENERATIONS = 1000;
const GENERATION_SIZE = 300;
const STATUS_IN_PROCESS = 0;
const STATUS_FINISHED = 1;
const STATUS_ERROR2 = 2; //range de solução muito limitada, não consegue criar individuos válidos o suficiente
const STATUS_ERROR3 = 3; //falha no generate_new_solution ou ou algum momento o rankedsolutions foi apagado ou seja, rankedsolutions = []

class HomePage extends StatefulWidget {
  Dumper dumper;
  HomePage({Key? key, required this.dumper}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState(dumper);
}


class _HomePageState extends State<HomePage> with TickerProviderStateMixin{
  late Dumper dumper;
  _HomePageState(this.dumper);
  late Timer _timer;
  int generation=0;
  DateTime startTime = DateTime.now();
  DateTime currentTime = DateTime.now();
  int currentExecutionTime = 0; //microseconds
  double averageExecutionTime = 0.0;//averageTime (microseconds) for each generation
  List<Individual> rankedsolutions = [];
  List<Individual> allsolutions = [];
  List<Individual> crossoversolutions = [];
  int algorithm_status = 0;
  double current_select_pressure=0.0;
  late TabController tabController;

  @override
  void initState(){
    super.initState();
    tabController=TabController(length: 3, vsync: this);
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {

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

        setState(() {
          var sel = selection_function(rankedsolutions, dumper.freq, dumper, LIMIT_GENERATIONS, GENERATION_SIZE);
          rankedsolutions = sel[0] as List<Individual>;
          algorithm_status = sel[1] as int;
          allsolutions = sel[2] as List<Individual>;

          current_select_pressure = select_pressure(allsolutions);

          List<Individual> clone_ranked = [];
          for(int i=0;i<rankedsolutions.length; i++){
            clone_ranked.add(Individual.from(rankedsolutions[i]));
          }
          crossoversolutions = crossover_function(clone_ranked, dumper);
          for(int i=0;i<crossoversolutions.length; i++){
            if(!individual_on_list(crossoversolutions[i], rankedsolutions)){
              rankedsolutions.add(Individual.from(crossoversolutions[i]));
            }
          }
        });

        List<Individual> clone_ranked2 = [];
        for(int i=0;i<rankedsolutions.length; i++){
          clone_ranked2.add(Individual.from(rankedsolutions[i]));
        }
        List<Individual> mutation = mutation_function(clone_ranked2, GENERATION_SIZE, dumper);
        setState(() {
          rankedsolutions = [];//erase all population
          for(int i=0;i<mutation.length; i++){
            if(!individual_on_list(mutation[i], rankedsolutions)){
              rankedsolutions.add(Individual.from(mutation[i]));
            }
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
      generation=0;
      startTime = DateTime.now();
      currentTime = DateTime.now();
      currentExecutionTime = 0; //microseconds
      averageExecutionTime = 0.0;//averageTime (microseconds) for each generation
      rankedsolutions = [];
      crossoversolutions = [];
      algorithm_status = 0;

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
                        IconButton(
                          padding: EdgeInsets.all(5),
                          constraints: BoxConstraints(),
                          icon: Icon(Icons.arrow_back, color: Colors.white,),
                          onPressed: (){
                            setState((){
                              dumper.count = 0;
                              algorithm_status = STATUS_FINISHED;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => FormPage(dumper: dumper,)
                                  ));
                            });
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5.5),
                          child: Image.asset('images/app_logo4.1.png'),
                        ),
                      ]),
                  Expanded(child: MoveWindow()),
                  const WindowButtons()
                ],
              ),
            ),
            Column(children: [
              Container(height: 0.7, color: Colors.white.withOpacity(0.3),),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 125,),
                  Container(
                    height: 26,
                    child: TabBar(
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.withOpacity(0.15),

                      ),
                      controller: tabController,
                      isScrollable: true,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 30),
                      tabs: const [
                        Tab(child: SizedBox(width: 70, child: Center(child: Text("Principal", style: TextStyle(color: Color(0xff62b5e5),),))),),
                        Tab(child: SizedBox(width: 70, child: Center(child: Text("Geral", style: TextStyle(color: Color(0xff62b5e5),),))),),
                        Tab(child: SizedBox(width: 70, child: Center(child: Text("Resultados", style: TextStyle(color: Color(0xff62b5e5),),))),),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 125,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Icon(Icons.play_arrow, color: Colors.green,),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Icon(Icons.pause, color: Colors.blue,),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Icon(Icons.stop, color: Colors.red,),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Container(height: 0.7, color: Colors.white.withOpacity(0.3),),
            ],),
            Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    ListView.builder(
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: 1,
                      itemBuilder: (context, index){
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 25,),
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
                              child: Text('Generations: $generation', style: TextStyle(color: Colors.white),),
                            ),
                            Column(children: [
                              for(int i=0; i<3;i++)
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(rankedsolutions.length < 3 ? 'Vazio' : 'individual[$i] - accuracy: ${(rankedsolutions[i].accuracy).toStringAsFixed(2)}, weight: ${(rankedsolutions[i].weight).toStringAsFixed(2)} Kg, aco = [${(rankedsolutions[i].aco[0][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[1][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[2][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[3][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[4][2]*1000).toStringAsFixed(1)}], borracha = [${(rankedsolutions[i].rigidez[0][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[1][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[2][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[3][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[4][2]*1000).toStringAsFixed(1)}]', style: TextStyle(color: Colors.white),),
                                ),
                            ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: Text('Select_pressure: ${current_select_pressure.toStringAsFixed(3)}', style: TextStyle(color: Colors.white),),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Text('Tempo de execução: ${printTimeFromMicroseconds(currentExecutionTime)}', style: TextStyle(color: Colors.white),),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Text('Tempo de execução média de uma geração: ${(averageExecutionTime/1000).toStringAsFixed(0)}ms', style: TextStyle(color: Colors.white),),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Text('Status: $algorithm_status', style: TextStyle(color: Colors.white),),
                            ),
                          ],
                        );
                      },
                    ),
                    ListView.builder(
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: 1,
                      itemBuilder: (context, index){
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            SizedBox(height: 25,),
                            Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text('Under construction...', style: TextStyle(color: Colors.white),),
                            ),

                          ],
                        );
                      },
                    ),
                    ListView.builder(
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: 1,
                      itemBuilder: (context, index){
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            SizedBox(height: 25,),
                            Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text('Under construction....', style: TextStyle(color: Colors.white),),
                            ),

                          ],
                        );
                      },
                    ),
                  ],
                ))
            // Expanded(
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: [
            //       Padding(
            //         padding: const EdgeInsets.all(0.0),
            //         child: Text('Objetivo: ${dumper.freq}', style: TextStyle(color: Colors.white),),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.all(0.0),
            //         child: Text(rankedsolutions.isNotEmpty ? 'Melhor resultado: ${rankedsolutions[0].vector_ans}' : 'Melhor resultado: []', style: TextStyle(color: Colors.white),),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.all(15.0),
            //         child: Text(rankedsolutions.isNotEmpty ? 'Erro: ${rankedsolutions[0].vector_errors}' : 'Erro: []', style: TextStyle(color: Colors.white),),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.only(top: 15.0),
            //         child: Text('Generations: $generation', style: TextStyle(color: Colors.white),),
            //       ),
            //       Column(children: [
            //         for(int i=0; i<3;i++)
            //           Padding(
            //             padding: const EdgeInsets.all(5.0),
            //             child: Text(rankedsolutions.length < 3 ? 'Vazio' : 'individual[$i] - accuracy: ${(rankedsolutions[i].accuracy).toStringAsFixed(2)}, weight: ${(rankedsolutions[i].weight).toStringAsFixed(2)} Kg, aco = [${(rankedsolutions[i].aco[0][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[1][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[2][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[3][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].aco[4][2]*1000).toStringAsFixed(1)}], borracha = [${(rankedsolutions[i].rigidez[0][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[1][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[2][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[3][2]*1000).toStringAsFixed(1)}, ${(rankedsolutions[i].rigidez[4][2]*1000).toStringAsFixed(1)}]', style: TextStyle(color: Colors.white),),
            //           ),
            //       ],
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.only(top: 0.0),
            //         child: Text('Select_pressure: ${current_select_pressure.toStringAsFixed(3)}', style: TextStyle(color: Colors.white),),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.only(top: 15.0),
            //         child: Text('Tempo de execução: ${printTimeFromMicroseconds(currentExecutionTime)}', style: TextStyle(color: Colors.white),),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.only(top: 15.0),
            //         child: Text('Tempo de execução média de uma geração: ${(averageExecutionTime/1000).toStringAsFixed(0)}ms', style: TextStyle(color: Colors.white),),
            //       ),
            //       Padding(
            //         padding: const EdgeInsets.only(top: 15.0),
            //         child: Text('Status: $algorithm_status', style: TextStyle(color: Colors.white),),
            //       ),
            //     ],
            //   ),
            // ),
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

