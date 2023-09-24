import 'dart:math';
import 'package:syncfusion_flutter_charts/charts.dart';
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

const LIMIT_GENERATIONS = 500;
const GENERATION_SIZE = 150;
const VIEW_INTERVAL = 150;
const STATUS_IN_PROCESS = 0;
const STATUS_SUCESSFULL = 1;//when reachs the errors targets
const STATUS_FINISHED = 2;//when reach the limit generation
const STATUS_PAUSE = 3;//button top stop
const STATUS_STOP = 4;//button to cancel
const STATUS_ERROR2 = 400; //range de solução muito limitada, não consegue criar individuos válidos o suficiente
const STATUS_ERROR3 = 401; //falha no generate_new_solution ou ou algum momento o rankedsolutions foi apagado ou seja, rankedsolutions = []
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
  int totalTime = 0; //microseconds
  int currentExecutionTime = 0; //microseconds
  int currentPauseTime = 0; //microseconds
  double averageExecutionTime = 0.0;//averageTime (microseconds) for each generation
  List<Individual> rankedsolutions = [];
  List<Individual> allsolutions = [];
  List<Individual> crossoversolutions = [];
  int algorithm_status = 0;
  bool force_stop = false;
  double current_select_pressure=0.0;
  bool side_left_menu_is_visible = true;
  bool side_right_menu_is_visible = true;
  late TabController tabController;
  final LinearGradient _linearGradient = const LinearGradient(
    colors: <Color>[
      Colors.green,
      Color(0xff0099ff),
      Color(0xff0000ff),
    ],
    stops: <double>[0.1, 0.3, 0.9],
    // Setting alignment for the series gradient
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Specifies the list of chart sample data.
  List<GraphData> chartBestAccuray_RT = <GraphData>[];
  List<GraphData> chartBestAccuray_RT_on_pause = <GraphData>[];
  List<GraphData> chartBestAccuray = <GraphData>[];
  double minViewChart = 0;
  double maxViewChart = VIEW_INTERVAL.toDouble();
  final Random random = Random();
  final TooltipBehavior _tooltipBehavior = TooltipBehavior(
      enable: true,
      borderColor: Colors.white,
      borderWidth: 2);
  @override
  void initState(){
    super.initState();
    tabController=TabController(length: 3, vsync: this);
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if(algorithm_status == STATUS_PAUSE){
        setState(() {
          currentPauseTime = totalTime-currentExecutionTime;
        });

      }
      if(generation != 0){
        setState(() {
          currentTime = DateTime.now();
          totalTime = currentTime.difference(startTime).inMicroseconds;
          averageExecutionTime = (totalTime-currentPauseTime)/generation;
        });
      }
      if(algorithm_status == STATUS_STOP || algorithm_status == STATUS_ERROR2 || algorithm_status == STATUS_ERROR3 || generation >= LIMIT_GENERATIONS){
        setState(() {
          force_stop = true;
        });
      }

      //inicio do algoritmo genetico
      //condição de parada, seja: o botão de parada, algum erro, seja ele por limite de tempo
      if(generation < LIMIT_GENERATIONS && algorithm_status == STATUS_IN_PROCESS && !force_stop && algorithm_status != STATUS_PAUSE){
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

          if(generation != 0){
            currentTime = DateTime.now();
            totalTime = currentTime.difference(startTime).inMicroseconds;
            currentExecutionTime = (totalTime-currentPauseTime);
            averageExecutionTime = (totalTime-currentPauseTime)/generation;
          }
        });
      }

      //atualizando vetores dos gráficos
      if(rankedsolutions.length != 0 && algorithm_status == STATUS_IN_PROCESS && generation < LIMIT_GENERATIONS){
        setState(() {
          chartBestAccuray_RT_on_pause.add(GraphData(generation.toDouble(), rankedsolutions[0].accuracy));
          chartBestAccuray_RT.add(GraphData(generation.toDouble(), rankedsolutions[0].accuracy+20));
          chartBestAccuray.add(GraphData(generation.toDouble(), rankedsolutions[0].accuracy));
          if(chartBestAccuray_RT.length > VIEW_INTERVAL){
            chartBestAccuray_RT.removeAt(0);
          }
        });
      }
      //fim do algoritmo genetico

    });
  }

  Widget MainPage(double current_width, double current_height){
    return Row(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.all(5),
                  constraints: BoxConstraints(),
                  icon: Icon(!side_left_menu_is_visible ? Icons.folder_open : Icons.maximize, color: Colors.white.withOpacity(0.8), size: 25),
                  onPressed: (){
                    setState((){
                      print("menu lateral");
                      side_left_menu_is_visible = !side_left_menu_is_visible;
                    });
                  },
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.decelerate,
                  // color: Color(0xff1c1c30),
                  width: side_left_menu_is_visible ? current_width*0.15 : 0,
                  // color: Colors.red,
                  child: Visibility(
                      visible: side_left_menu_is_visible,
                      child: Text('width: ${current_width*0.2}', style: TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            ),
            Container(
              width: 0.7,
              color: Color(0xff595959).withOpacity(0.3),
            ),
          ],

        ),
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 25,),
              Container(
                margin: const EdgeInsets.only(left: 20.0, right: 20),
                height: current_height*0.55,
                child: SfCartesianChart(
                  title: ChartTitle(
                    text: 'Geração x Precisão',
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Roboto',
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      )
                  ),
                  tooltipBehavior: _tooltipBehavior,
                  margin: const EdgeInsets.only(top: 10, right: 10),
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePanning: true,
                    enableMouseWheelZooming: true,
                    enablePinching: true,
                  ),
                  primaryXAxis: NumericAxis(
                    // visibleMinimum: algorithm_status == STATUS_IN_PROCESS ? null : minViewChart,
                    // visibleMaximum: algorithm_status == STATUS_IN_PROCESS ? null : maxViewChart,
                    interval: 50,
                    decimalPlaces: 0,
                    title: AxisTitle(
                        text: 'Geração',
                        textStyle: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300
                        )
                    )
                  ),
                  primaryYAxis: NumericAxis(
                    interval: 10,
                      title: AxisTitle(
                          text: 'Precisão',
                          textStyle: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300
                          )
                      )
                  ),
                  series: <LineSeries<GraphData, num>>[
                    LineSeries<GraphData, num>(
                      dataSource: algorithm_status == STATUS_IN_PROCESS ? chartBestAccuray_RT : chartBestAccuray_RT_on_pause,
                      // gradient: _linearGradient,
                      color: Colors.red,
                      width: 3,
                      xValueMapper: (GraphData data, _) => data.x,
                      yValueMapper: (GraphData data, _) => data.y,
                    ),
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(0.0),
              //   child: Text('Objetivo: ${dumper.freq}', style: TextStyle(color: Colors.white),),
              // ),
              // Padding(
              //   padding: const EdgeInsets.all(0.0),
              //   child: Text(rankedsolutions.isNotEmpty ? 'Melhor resultado: ${rankedsolutions[0].vector_ans}' : 'Melhor resultado: []', style: TextStyle(color: Colors.white),),
              // ),
              // Padding(
              //   padding: const EdgeInsets.all(15.0),
              //   child: Text(rankedsolutions.isNotEmpty ? 'Erro: ${rankedsolutions[0].vector_errors}' : 'Erro: []', style: TextStyle(color: Colors.white),),
              // ),
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
                child: Text('Status: $algorithm_status', style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 0.7,
              color: Color(0xff595959).withOpacity(0.3),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: IconButton(
                    padding: EdgeInsets.all(5),
                    constraints: BoxConstraints(),
                    icon: Icon(!side_right_menu_is_visible ? Icons.folder_open : Icons.maximize, color: Colors.white.withOpacity(0.8), size: 25),
                    onPressed: (){
                      setState((){
                        print("menu lateral dir");
                        side_right_menu_is_visible = !side_right_menu_is_visible;
                      });
                    },
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.decelerate,
                  // color: Color(0xff1c1c30),
                  width: side_right_menu_is_visible ? current_width*0.15 : 0,
                  // color: Colors.red,
                  child: Visibility(
                      visible: side_right_menu_is_visible,
                      child: Text('width: ${current_width*0.2}', style: TextStyle(color: Colors.white),)
                  ),
                ),
              ],
            )
          ],

        ),
      ],
    );
  }

  Widget build(BuildContext context) {


    var currentWidth = MediaQuery.of(context).size.width;
    var currentHeight = MediaQuery.of(context).size.height;
    if(dumper.count == 0){
      generation=0;
      startTime = DateTime.now();
      currentTime = DateTime.now();
      totalTime = 0; //microseconds
      currentPauseTime = 0; //microseconds
      currentExecutionTime = 0; //microseconds
      averageExecutionTime = 0.0;//averageTime (microseconds) for each generation
      rankedsolutions = [];
      allsolutions = [];
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
              child: Container(
                color: Color(0xff1c1c31),
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
                                algorithm_status = STATUS_SUCESSFULL;
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
            ),
            Column(children: [
              Container(height: 0.7, color: Colors.white.withOpacity(0.3),),
              Container(
                color: Color(0xff22223a),
                child: Row(
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
                          Tab(child: SizedBox(width: 80, child: Center(child: Text("Principal", style: TextStyle(color: Color(0xff62b5e5),),))),),
                          Tab(child: SizedBox(width: 80, child: Center(child: Text("Visão Geral", style: TextStyle(color: Color(0xff62b5e5),),))),),
                          Tab(child: SizedBox(width: 80, child: Center(child: Text("Resultados", style: TextStyle(color: Color(0xff62b5e5),),))),),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 125,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                Icons.play_arrow,
                                color: ((){
                                  if(!force_stop && algorithm_status != STATUS_IN_PROCESS){
                                    return const Color(0xff33ff33);
                                  }else{
                                    return const Color(0xff006600);
                                  }
                                }()),
                              ),
                              onPressed: () {

                                if(!force_stop && algorithm_status != STATUS_IN_PROCESS){
                                  print("play");
                                  setState(() {
                                    algorithm_status = STATUS_IN_PROCESS;
                                  });
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: IconButton(
                              hoverColor: Colors.grey.withOpacity(0.15),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                Icons.pause,
                                color: ((){
                                  if(!force_stop && algorithm_status != STATUS_PAUSE){
                                    return const Color(0xff1a1aff);
                                  }else{
                                    return const Color(0xff000066);
                                  }
                                }()),
                              ),
                              onPressed: () {
                                if(!force_stop && algorithm_status != STATUS_PAUSE){
                                  print("pause");
                                  setState(() {
                                    if(generation < VIEW_INTERVAL){
                                      minViewChart = 1;
                                      maxViewChart = generation.toDouble();
                                    }else{
                                      minViewChart = (generation-VIEW_INTERVAL).toDouble();
                                      maxViewChart = generation.toDouble();
                                    }
                                    algorithm_status = STATUS_PAUSE;
                                  });
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: IconButton(
                              hoverColor: Colors.grey.withOpacity(0.15),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                Icons.stop,
                                color: ((){
                                  if(force_stop){
                                    return const Color(0xff660000);
                                  }else{
                                    return const Color(0xffFF0000);
                                  }
                                }()),
                              ),
                              onPressed: () {
                                setState(() {
                                  if(!force_stop){
                                    print("stop");
                                    setState(() {
                                      algorithm_status = STATUS_STOP;
                                      force_stop = true;
                                    });
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Container(height: 0.7, color: Colors.white.withOpacity(0.3),),
            ],),
            Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    MainPage(currentWidth, currentHeight),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 25,),
                        Padding(
                          padding: EdgeInsets.all(0.0),
                          child: Text('Under construction...', style: TextStyle(color: Colors.white),),
                        ),
                        Padding(
                            padding: EdgeInsets.all(100),
                            child: SfCartesianChart(
                              tooltipBehavior: _tooltipBehavior,
                              margin: const EdgeInsets.only(top: 10, right: 10),
                              zoomPanBehavior: ZoomPanBehavior(
                                enablePanning: true,
                                enableMouseWheelZooming: true,
                                enablePinching: true,
                              ),
                              primaryXAxis: NumericAxis(
                                decimalPlaces: 0,
                              ),
                              primaryYAxis: NumericAxis(),
                              series: <SplineAreaSeries<GraphData, num>>[
                                SplineAreaSeries<GraphData, num>(
                                  dataSource: chartBestAccuray,
                                  gradient: _linearGradient,
                                  // color: Colors.red,
                                  xValueMapper: (GraphData data, _) => data.x,
                                  yValueMapper: (GraphData data, _) => data.y,

                                ),
                              ],
                            ),
                        )
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        SizedBox(height: 25,),
                        Padding(
                          padding: EdgeInsets.all(0.0),
                          child: Text('Under construction....', style: TextStyle(color: Colors.white),),
                        ),

                      ],
                    ),
                  ],
                )),
            Column(children: [
              Container(height: 0.7, color: Colors.white.withOpacity(0.3),),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Transform.rotate(angle: 3.1415, child: const Icon(Icons.copy, color: Colors.white, size: 20,),),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Text('Tempo total: ${printTimeFromMicroseconds(totalTime)}, Tempo de execução: ${printTimeFromMicroseconds(currentExecutionTime)}, Tempo de pausa: ${printTimeFromMicroseconds(currentPauseTime)}, Tempo de execução média de uma geração: ${(averageExecutionTime/1000).toStringAsFixed(0)}ms', style: TextStyle(color: Colors.white, fontSize: 12),),
                    ),
                  ),
                  SizedBox(width: 24,)
                ],
              )
            ],),
          ]
        ),
      )
    );
  }
}
class GraphData{
  final double x;
  final double y;
  GraphData(this.x, this.y);
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

