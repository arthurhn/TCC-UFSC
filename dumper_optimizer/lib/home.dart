import 'dart:math';
import 'package:data/data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
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

// const LIMIT_GENERATIONS = 150;
// const GENERATION_SIZE = 250;
// const VIEW_INTERVAL = 100;
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
  double average_error=0.0;
  bool side_left_menu_is_visible = true;
  bool side_left_menu_is_visible_results = true;
  bool side_right_menu_is_visible = true;
  int individual_select = 0; //which individual that will appear in the results
  int oneTimeAfterEnd = 0;//when reaches limit_generetion, activate one time setState and after that it can't setState to fast because of tooltip
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
  List<GraphData> chartSelectPressure_RT = <GraphData>[];
  List<GraphData> chartSelectPressure_RT_on_pause = <GraphData>[];
  List<GraphDataColumn> chartErrorByFrequency_RT = <GraphDataColumn>[GraphDataColumn('0', 0), GraphDataColumn('0', 0), GraphDataColumn('0', 0), GraphDataColumn('0', 0), GraphDataColumn('0', 0)];//GraphData(dumper.freq[0], dumper.freq_error[0])
  List<GraphDataColumn> chartErrorByFrequency_RT_teste = <GraphDataColumn>[GraphDataColumn('1000', 10), GraphDataColumn('900', 20), GraphDataColumn('500', 10), GraphDataColumn('300', 5), GraphDataColumn('200', 1)];//GraphData(dumper.freq[0], dumper.freq_error[0])
  List<GraphData> chartBestAccuray_OV = <GraphData>[];
  String select_chart = 'accuracy';
  final Random random = Random();
  bool darkMode = true;
  bool useSides = true;
  int pauseOneTime = 0;

  @override
  void initState(){
    super.initState();
    tabController=TabController(length: 3, vsync: this);
    //obs: se colocar setState enquanto esta no pause ele n consegue ver oca
    _timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if(algorithm_status == STATUS_PAUSE){
        currentPauseTime = totalTime-currentExecutionTime;
      }
      if(generation != 0 && (algorithm_status == STATUS_IN_PROCESS || algorithm_status == STATUS_PAUSE)){
        currentTime = DateTime.now();
        totalTime = currentTime.difference(startTime).inMicroseconds;
        averageExecutionTime = (totalTime-currentPauseTime)/generation;
      }
      if(algorithm_status == STATUS_STOP || algorithm_status == STATUS_ERROR2 || algorithm_status == STATUS_ERROR3 || generation >= dumper.limit_generation || algorithm_status == STATUS_SUCESSFULL){
        if(generation >= dumper.limit_generation && oneTimeAfterEnd == 0){
          setState(() {
            algorithm_status = STATUS_FINISHED;
            tabController.animateTo(2);
            oneTimeAfterEnd++;
          });
        }
        force_stop = true;
      }
      if(algorithm_status == STATUS_SUCESSFULL && oneTimeAfterEnd == 0){
        setState(() {
          tabController.animateTo(2);
          oneTimeAfterEnd++;
        });
      }
      if(tabController.index == 2 && pauseOneTime == 0){
        setState(() {
          print("setState");
          pauseOneTime++;
          algorithm_status = STATUS_PAUSE;
        });
      }

      //inicio do algoritmo genetico
      //condição de parada, seja: o botão de parada, algum erro, seja ele por limite de tempo
      if(generation < dumper.limit_generation && algorithm_status == STATUS_IN_PROCESS && !force_stop && algorithm_status != STATUS_PAUSE){
        //primeira vez na tela home
        if(rankedsolutions.isEmpty && generation == 0){
          int count = 0;
          print("------------- first gen --------------");
          rankedsolutions = generate_new_solution(dumper.generation_size, dumper);
          while(rankedsolutions.isEmpty && count < 1000){
            rankedsolutions = generate_new_solution(dumper.generation_size, dumper);
            count++;
          }
          if(count >= 1000){
            algorithm_status = STATUS_ERROR2;
          }
        }

        setState(() {
          var sel = selection_function(rankedsolutions, dumper.freq, dumper, dumper.limit_generation, dumper.generation_size);
          rankedsolutions = sel[0] as List<Individual>;
          algorithm_status = sel[1] as int;
          allsolutions = sel[2] as List<Individual>;

          if(rankedsolutions.isNotEmpty){
            average_error = rankedsolutions[0].vector_errors.average();
          }
          current_select_pressure = select_pressure(allsolutions);

          //cloning for pass to mutation as parameter
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

        //cloning for pass to mutation as parameter
        List<Individual> clone_ranked2 = [];
        for(int i=0;i<rankedsolutions.length; i++){
          clone_ranked2.add(Individual.from(rankedsolutions[i]));
        }
        List<Individual> mutation = mutation_function(clone_ranked2, dumper.generation_size, dumper);
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
      //fim do algoritmo genetico

      //atualizando vetores dos gráficos
      if(rankedsolutions.length != 0 && algorithm_status == STATUS_IN_PROCESS && generation < dumper.limit_generation){
        setState(() {
          chartBestAccuray_RT_on_pause.add(GraphData(generation.toDouble(), rankedsolutions[0].accuracy));
          chartBestAccuray_RT.add(GraphData(generation.toDouble(), rankedsolutions[0].accuracy));

          chartSelectPressure_RT_on_pause.add(GraphData(generation.toDouble(), current_select_pressure));
          chartSelectPressure_RT.add(GraphData(generation.toDouble(), current_select_pressure));

          for(int i=0; i<dumper.freq.length;i++){
            chartErrorByFrequency_RT[i] = GraphDataColumn(dumper.freq[i].toStringAsFixed(0), rankedsolutions[0].vector_errors[i]);
          }
          //GraphData(dumper.freq[0], dumper.freq_error[0])
          chartBestAccuray_OV.add(GraphData(generation.toDouble(), rankedsolutions[0].accuracy));
          if(generation > dumper.view_interval){
            chartBestAccuray_RT.removeAt(0);
            chartSelectPressure_RT.removeAt(0);
          }
        });
      }


    });
  }

  TooltipBehavior _tooltipBehavior(String headerText) {
    return TooltipBehavior(
      enable: true,
      borderColor: Colors.white,
      borderWidth: 2,
      header: headerText,
    );
  }
  TooltipBehavior _tooltipBehaviorThickness(String headerText, Individual ind, ) {
    return TooltipBehavior(
        enable: true,
        borderColor: Colors.white,
        borderWidth: 2,
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {

          double oneThickness = 0.0;
          List<double> formationThickness = [];
          int position = seriesIndex.toInt();
          if(position == 0){
            oneThickness = data.y1;
            formationThickness = ind.genesis_rigidez_mm[0];
          }if(position == 1){
            oneThickness = data.y2;
            formationThickness = ind.genesis_aco_mm[0];
          }if(position == 2){
            oneThickness = data.y3;
            formationThickness = ind.genesis_rigidez_mm[1];
          }if(position == 3){
            oneThickness = data.y4;
            formationThickness = ind.genesis_aco_mm[1];
          }if(position == 4){
            oneThickness = data.y5;
            formationThickness = ind.genesis_rigidez_mm[2];
          }if(position == 5){
            oneThickness = data.y6;
            formationThickness = ind.genesis_aco_mm[2];
          }if(position == 6){
            oneThickness = data.y7;
            formationThickness = ind.genesis_rigidez_mm[3];
          }if(position == 7){
            oneThickness = data.y8;
            formationThickness = ind.genesis_aco_mm[3];
          }if(position == 8){
            oneThickness = data.y9;
            formationThickness = ind.genesis_rigidez_mm[4];
          }if(position == 9){
            oneThickness = data.y10;
            formationThickness = ind.genesis_aco_mm[4];
          }


          return Container(
            decoration:  BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Espessura : $oneThickness mm\nFormação: $formationThickness mm',
                  style: TextStyle(color: Colors.white),
                )
            ),
          );
        }
    );
  }

  Widget SelectChart(String select, double current_width, double current_height, bool isCorner, [int individualPosition=0]){
    if(select == 'accuracy'){
       return Container(
         margin: !isCorner ? EdgeInsets.only(left: 20.0, right: 20) : EdgeInsets.only(left: 10, right: 10),
         height: !isCorner ? current_height*0.55 : 80,
         child: SfCartesianChart(
           title: ChartTitle(
               text: !isCorner ? 'Geração x Precisão' : 'Precisão',
               textStyle: TextStyle(
                 color: Colors.white,
                 fontFamily: 'Roboto',
                 fontStyle: FontStyle.italic,
                 fontSize: !isCorner ? 14 : 10,
               )
           ),
           tooltipBehavior: !isCorner && algorithm_status != STATUS_IN_PROCESS ?  _tooltipBehavior('Precisão') : null,
           margin: const EdgeInsets.only(top: 10, right: 10),
           zoomPanBehavior: !isCorner ? ZoomPanBehavior(
             enablePanning: true,
             enableMouseWheelZooming: true,
             enablePinching: true,
           ) :  null,
           primaryXAxis: NumericAxis(
             interval: 50,
             decimalPlaces: 0,
             title: !isCorner ? AxisTitle(
                 text: 'Geração',
                 textStyle: const TextStyle(
                     color: Colors.white,
                     fontFamily: 'Roboto',
                     fontSize: 16,
                     fontStyle: FontStyle.italic,
                     fontWeight: FontWeight.w300
                 )
             ) : null,
             isVisible: !isCorner ? true : false,
           ),
           primaryYAxis: NumericAxis(
             interval: 10,
             title: !isCorner ? AxisTitle(
                 text: 'Precisão',
                 textStyle: const TextStyle(
                     color: Colors.white,
                     fontFamily: 'Roboto',
                     fontSize: 16,
                     fontStyle: FontStyle.italic,
                     fontWeight: FontWeight.w300
                 )
           ) : null,
             isVisible: !isCorner ? true : false,
           ),
           series: <LineSeries<GraphData, num>>[
             LineSeries<GraphData, num>(
               dataSource: algorithm_status == STATUS_IN_PROCESS ? chartBestAccuray_RT : chartBestAccuray_RT_on_pause,
               color: Colors.greenAccent,
               width: 3,
               xValueMapper: (GraphData data, _) => data.x,
               yValueMapper: (GraphData data, _) => data.y,
             ),
           ],
         ),
       );
    }else if (select == 'select_pressure'){
      return Container(
        margin: !isCorner ? EdgeInsets.only(left: 20.0, right: 20) : EdgeInsets.only(left: 10, right: 10),
        height: !isCorner ? current_height*0.55 : 80,
        child: SfCartesianChart(
          title: ChartTitle(
            text: !isCorner ? 'Geração x Select Pressure' : 'Select Pressure',
            textStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontStyle: FontStyle.italic,
              fontSize: !isCorner ? 14 : 10,
            )
          ),
          tooltipBehavior: !isCorner && algorithm_status != STATUS_IN_PROCESS ?  _tooltipBehavior('Precisão') : null,
          margin: const EdgeInsets.only(top: 10, right: 10),
          zoomPanBehavior: !isCorner ? ZoomPanBehavior(
            enablePanning: true,
            enableMouseWheelZooming: true,
            enablePinching: true,
          ) :  null,
          primaryXAxis: NumericAxis(
            interval: 50,
            decimalPlaces: 0,
            title: !isCorner ? AxisTitle(
                text: 'Geração',
                textStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300
                )
            ) : null,
            isVisible: !isCorner ? true : false,
          ),
          primaryYAxis: NumericAxis(
            title: !isCorner ? AxisTitle(
                text: 'Select Pressure',
                textStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300
                )
            ) : null,
            isVisible: !isCorner ? true : false,
          ),
          series: <LineSeries<GraphData, num>>[
            LineSeries<GraphData, num>(
              dataSource: algorithm_status == STATUS_IN_PROCESS ? chartSelectPressure_RT : chartSelectPressure_RT_on_pause,
              color: Colors.orangeAccent,
              width: 3,
              xValueMapper: (GraphData data, _) => data.x,
              yValueMapper: (GraphData data, _) => data.y,

            ),
          ],
        ),
      );
    }else if (select == 'errors_by_freq'){
      return Container(
        margin: !isCorner ? const EdgeInsets.only(left: 20.0, right: 20) : const EdgeInsets.only(left: 10, right: 10),
        height: !isCorner ? current_height*0.55 : 80,
        child: SfCartesianChart(
          tooltipBehavior: algorithm_status == STATUS_IN_PROCESS ? null : _tooltipBehavior('Erro por Freq.'),
          title: ChartTitle(
            // margin: EdgeInsets.zero,
            text: !isCorner ? 'Erro em cada frequência' : 'Erros',
            textStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontStyle: FontStyle.italic,
              fontSize: !isCorner ? 14 : 10,
            ),
          ),
          margin: const EdgeInsets.only(top: 10, right: 10),
          zoomPanBehavior: !isCorner ? ZoomPanBehavior(
            enablePanning: true,
            enableMouseWheelZooming: true,
            enablePinching: true,
          ) :  null,
          primaryXAxis: CategoryAxis(
            isVisible: !isCorner ? true : false,
            title: !isCorner ? AxisTitle(
                text: 'Frequência',
                textStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300
                )
            ) : null,

          ),
          primaryYAxis: NumericAxis(
            title: !isCorner ? AxisTitle(
                text: 'Erro (%)',
                textStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300
                )
            ) : null,
            isVisible: !isCorner ? true : false,
          ),
          series: <ColumnSeries<GraphDataColumn, String>>[
            ColumnSeries<GraphDataColumn, String>(
              dataSource: chartErrorByFrequency_RT,
              color: Colors.redAccent,
              xValueMapper: (GraphDataColumn data, _) => data.x,
              yValueMapper: (GraphDataColumn data, _) => data.y*100,
            ),
          ],
        ),
      );
    }else if (select == 'errors_by_freq_radar'){
      const ticks = [10, 20, 30, 40, 50];
      List<String> features = ["Freq. 1", "Freq. 2", "Freq. 3", "Freq. 4", "Freq. 5",];
      for(int i=0; i<dumper.freq.length; i++){
        features[i] = "${dumper.freq[i]} Hz";
      }
      List<List<double>> data = [];
      if(rankedsolutions.length >= 5){
        data.add([]);
        for(int j=0; j<5; j++){
          if(rankedsolutions[individualPosition].vector_errors[j]*100 > 50){
            data[0].add(50);
          }else{
            data[0].add(double.parse((rankedsolutions[individualPosition].vector_errors[j]*100).toStringAsFixed(2)));
          }
        }

      }
      return Column(
        children: [
          const Text(
            'Erros (%) por frequência',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontStyle: FontStyle.italic,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 5,),
          Expanded(
            child: RadarChart.dark(
              ticks: ticks,
              features: features,
              data: data,
              reverseAxis: true,
              useSides: true,
              // graphColors: [Colors.orange],
            ),
          ),
        ],
      );
    }
    return Container();
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
                      print("menu lateral dir");
                      side_left_menu_is_visible = !side_left_menu_is_visible;
                    });
                  },
                ),
                Container(
                  // duration: const Duration(milliseconds: 200),
                  // curve: Curves.decelerate,
                  width: side_left_menu_is_visible ? current_width*0.18 : 0,
                  child: Visibility(
                      visible: side_left_menu_is_visible,
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 0, bottom: 8),
                            child: const Text(
                              'Gráficos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Container(
                            height: 85,
                            margin: EdgeInsets.only(left: 8, right: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 5,
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: IgnorePointer(
                                child: SelectChart('accuracy', current_width, current_height, true),
                              ),
                              onPressed: () {
                                print('accuracy');
                                setState(() {
                                  select_chart = 'accuracy';
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 4,),
                          Container(
                            height: 85,
                            margin: EdgeInsets.only(left: 8, right: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 5,
                                backgroundColor: Colors.transparent,
                                // shadowColor: Colors.transparent.withOpacity(0.1),
                                // side: const BorderSide(
                                //   width: 2,
                                //   color: Colors.grey,
                                // ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: IgnorePointer(
                                child: SelectChart('select_pressure', current_width, current_height, true),
                              ),
                              onPressed: () {
                                print('select_pressure');
                                setState(() {
                                  select_chart = 'select_pressure';
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 4,),
                          Container(
                            height: 85,
                            margin: EdgeInsets.only(left: 8, right: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 5,
                                backgroundColor: Colors.transparent,
                                // shadowColor: Colors.transparent.withOpacity(0.1),
                                // side: const BorderSide(
                                //   width: 2,
                                //   color: Colors.grey,
                                // ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: IgnorePointer(
                                child: SelectChart('errors_by_freq', current_width, current_height, true),
                              ),
                              onPressed: () {
                                print('errors_by_freq');
                                setState(() {
                                  select_chart = 'errors_by_freq';
                                });
                              },
                            ),
                          ),
                        ],
                      )
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
              SizedBox(height: 20,),
              SelectChart(select_chart, current_width, current_height, false),
              SizedBox(height: 10,),
              Container(
                height: 0.7,
                color: Color(0xff595959).withOpacity(0.3),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 40.0, right: 0, top: 15, bottom: 0),
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.center,child: Text('Melhor Indivíduo', style: TextStyle(color: Colors.white, fontSize: 16),)),
                      SizedBox(height: 4,),
                      Text(rankedsolutions.isEmpty ? 'Vazio' : 'Precisão: ${rankedsolutions[0].accuracy.toStringAsFixed(2)}', style: TextStyle(color: Colors.white),),
                      SizedBox(height: 4,),
                      Text(rankedsolutions.isEmpty ? 'Vazio' : 'Massa: ${rankedsolutions[0].weight.toStringAsFixed(2)} Kg', style: TextStyle(color: Colors.white),),
                      SizedBox(height: 4,),
                      Text('Erro médio: ${(average_error*100).toStringAsFixed(2)}%', style: TextStyle(color: Colors.white),),
                      SizedBox(height: 4,),
                      Text(rankedsolutions.isEmpty ? 'Vazio' : 'Erro por frequência: [${(rankedsolutions[0].vector_errors[0]*100).toStringAsFixed(1)}, ${(rankedsolutions[0].vector_errors[1]*100).toStringAsFixed(1)}, ${(rankedsolutions[0].vector_errors[2]*100).toStringAsFixed(1)}, ${(rankedsolutions[0].vector_errors[3]*100).toStringAsFixed(1)}, ${(rankedsolutions[0].vector_errors[4]*100).toStringAsFixed(1)}]%', style: TextStyle(color: Colors.white),),
                      SizedBox(height: 4,),
                      Text('Select Pressure: ${current_select_pressure.toStringAsFixed(3)}', style: TextStyle(color: Colors.white),),
                      SizedBox(height: 4,),
                      //Text(rankedsolutions.isNotEmpty ? 'Formação rig: ${rankedsolutions[0].genesis_rigidez_mm}, Formação aco: ${rankedsolutions[0].genesis_aco_mm}' : 'Vazio', style: TextStyle(color: Colors.white),),
                      //Text(rankedsolutions.isNotEmpty ? 'aco: ${rankedsolutions[0].aco}' : 'Vazio', style: TextStyle(color: Colors.white),),
                    ],
                  ),
                ),
              )
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
                        if(!side_right_menu_is_visible){
                          side_right_menu_is_visible = false;
                        }else{
                          side_right_menu_is_visible = true;
                        }
                      });
                    },
                  ),
                ),
                Container(
                  width: ((){
                    if(side_right_menu_is_visible){
                      if(current_width*0.22 < 220){
                        return 220.0;
                      }else{
                        return current_width*0.22;
                      }
                    }else{
                      return 0.0;
                    }
                  }()),
                  child: Visibility(
                      visible: side_right_menu_is_visible,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 0, top: 0, bottom: 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(alignment: Alignment.center,child: Text('Parâmetros', style: TextStyle(color: Colors.white, fontSize: 16),)),
                            SizedBox(height: 10,),
                            Text(dumper.freq.isEmpty ? 'Vazio' : 'Objetivos (Frequências):\n[${dumper.freq[0].toStringAsFixed(0)}, ${dumper.freq[1].toStringAsFixed(0)}, ${dumper.freq[2].toStringAsFixed(0)}, ${dumper.freq[3].toStringAsFixed(0)}, ${dumper.freq[4].toStringAsFixed(0)}] Hz', style: TextStyle(color: Colors.white),),
                            SizedBox(height: 3,),
                            Text(dumper.freq_error.isEmpty ? 'Vazio' : 'Peso das frequências: \n(Mudar aqui)', style: TextStyle(color: Colors.white),),
                            SizedBox(height: 3,),
                            Text('Largura: ${(dumper.width*1000).toStringAsFixed(1)} mm', style: TextStyle(color: Colors.white),),
                            SizedBox(height: 3,),
                            Text('Comprimento: ${(dumper.lenght*100).toStringAsFixed(1)} cm', style: TextStyle(color: Colors.white),),
                            SizedBox(height: 3,),
                            Text('Intervalo de Peso: [${(dumper.min_weight).toStringAsFixed(1)}, ${(dumper.max_weight).toStringAsFixed(1)}] Kg', style: TextStyle(color: Colors.white),),
                            SizedBox(height: 3,),
                            Text('Intervalo de espessura de mola:\n[${(dumper.min_springThickness_mm).toStringAsFixed(1)}, ${(dumper.max_springThickness_mm).toStringAsFixed(1)}] mm', style: TextStyle(color: Colors.white),),
                            Text(((){
                                String response = '    - Opções de mola: [';
                                for(int i=0; i<dumper.springOptions.length; i++){
                                  if(i!=dumper.springOptions.length-1){
                                    response = '$response${(dumper.springOptions[i]).toStringAsFixed(1)}, ';
                                  }else{
                                    response = '$response${(dumper.springOptions[i]).toStringAsFixed(1)}] mm';
                                  }
                                }
                                return response;
                              }()),
                              style: TextStyle(color: Colors.white),
                              ),
                            SizedBox(height: 3,),
                            Text('Intervalo de espessura de aço:\n[${(dumper.min_massThickness_mm).toStringAsFixed(1)}, ${(dumper.max_massThickness_mm).toStringAsFixed(1)}] mm', style: TextStyle(color: Colors.white),),
                            Text(((){
                              String response = '    - Opções de aço: [';
                              for(int i=0; i<dumper.massOptions.length; i++){
                                if(i!=dumper.massOptions.length-1){
                                  response = '$response${(dumper.massOptions[i]).toStringAsFixed(1)}, ';
                                }else{
                                  response = '$response${(dumper.massOptions[i]).toStringAsFixed(1)}] mm';
                                }
                              }
                              return response;
                            }()),
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 3,),
                            Text('Densidade da mola ${(dumper.springDensity).toStringAsFixed(0)} Kg/m^3', style: TextStyle(color: Colors.white),),
                            SizedBox(height: 3,),
                            Text('Elasticidade da mola ${(dumper.springElasticity/pow(10, 6)).toStringAsFixed(2)} MPa', style: TextStyle(color: Colors.white),),
                            SizedBox(height: 3,),
                            Text('Densidade do aço ${(dumper.massDensity).toStringAsFixed(0)} Kg/m^3', style: TextStyle(color: Colors.white),),
                          ],
                        ),
                      )
                  ),
                ),
              ],
            )
          ],

        ),
      ],
    );
  }

  Widget OverViewPage(double current_width, double current_height){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 50,
              child: Container(
                margin: const EdgeInsets.only(left: 50, top: 30, right: 10, bottom: 10),
                height: current_height*0.4,
                // width: current_width*0.42,
                child: SfCartesianChart(
                  title: ChartTitle(
                      text: 'Geração x Precisão',
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Roboto',
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      )
                  ),
                  tooltipBehavior: algorithm_status != STATUS_IN_PROCESS ?  _tooltipBehavior('Precisão') : null,
                  margin: const EdgeInsets.only(top: 10, right: 10),
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePanning: true,
                    enableMouseWheelZooming: true,
                    enablePinching: true,
                  ),
                  primaryXAxis: NumericAxis(
                    interval: ((){
                      if(generation < 50){
                        return 5.0;
                      }else if(generation < 100){
                        return 10.0;
                      }else if(generation < 200){
                        return 20.0;
                      }else{
                        return 50.0;
                      }
                    }()),
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
                    ),
                    isVisible: true,
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(
                        text: 'Precisão',
                        textStyle: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300
                        )
                    ),
                    isVisible: true,
                  ),
                  series: <SplineAreaSeries<GraphData, num>>[
                    SplineAreaSeries<GraphData, num>(
                      dataSource: chartBestAccuray_RT_on_pause,
                      gradient: const LinearGradient(
                        colors: <Color>[
                          Colors.green,
                          Color(0xff0099ff),
                          Color(0xff0000ff),
                        ],
                        stops: <double>[0.1, 0.3, 0.9],
                        // Setting alignment for the series gradient
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      xValueMapper: (GraphData data, _) => data.x,
                      yValueMapper: (GraphData data, _) => data.y,

                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 50,
              child: Container(
                margin: const EdgeInsets.only(left: 10, top: 30, right: 50, bottom: 10),
                // width: current_width*0.42,
                height: current_height*0.4,
                child: SfCartesianChart(
                  title: ChartTitle(
                      text: 'Geração x Select Pressure',
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Roboto',
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      )
                  ),
                  tooltipBehavior: algorithm_status != STATUS_IN_PROCESS ?  _tooltipBehavior('Select Pressure') : null,
                  margin: const EdgeInsets.only(top: 10, right: 10),
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePanning: true,
                    enableMouseWheelZooming: true,
                    enablePinching: true,
                  ),
                  primaryXAxis: NumericAxis(
                    interval: ((){
                      if(generation < 50){
                        return 5.0;
                      }else if(generation < 100){
                        return 10.0;
                      }else if(generation < 200){
                        return 20.0;
                      }else{
                        return 50.0;
                      }
                      }()),
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
                    ),
                    isVisible: true,
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(
                        text: 'Select Pressure',
                        textStyle: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300
                        )
                    ),
                    isVisible: true,
                  ),
                  series: <SplineAreaSeries<GraphData, num>>[
                    SplineAreaSeries<GraphData, num>(
                      dataSource: chartSelectPressure_RT_on_pause,
                      gradient: const LinearGradient(
                        colors: <Color>[
                          Colors.redAccent,
                          Colors.orange,
                          Colors.orangeAccent,
                        ],
                        stops: <double>[0.1, 0.3, 0.9],
                        // Setting alignment for the series gradient
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      // color: Colors.red,
                      xValueMapper: (GraphData data, _) => data.x,
                      yValueMapper: (GraphData data, _) => data.y,

                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 50, top: 0, right: 50, bottom: 10),
              child: SelectChart('errors_by_freq', current_width, current_height, false)
            )
        ),
      ],
    );
  }

  Widget ResultsPage(double current_width, double current_height, int individualPosition){

    List<double> rigidez_mm = [];
    List<double> aco_mm = [];
    if(rankedsolutions.length > 5){
      for(int i=0; i<rankedsolutions[individualPosition].rigidez.length; i++){
        rigidez_mm.add((rankedsolutions[individualPosition].rigidez[i][2]*100000).roundToDouble()/100);
      }
      for(int i=0; i<rankedsolutions[individualPosition].aco.length; i++){
        aco_mm.add((rankedsolutions[individualPosition].aco[i][2]*100000).roundToDouble()/100);
      }
    }
    List<ChartData> chartData = [
      ChartData(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    ];
    if(rankedsolutions.isNotEmpty){
      chartData = [
        ChartData(0, rigidez_mm[0], aco_mm[0], rigidez_mm[1], aco_mm[1], rigidez_mm[2], aco_mm[2], rigidez_mm[3], aco_mm[3], rigidez_mm[4], aco_mm[4]),
        // ChartData(1, 14, 15, 18, 23, 22, 12),
      ];
    }

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
                  icon: Icon(!side_left_menu_is_visible_results ? Icons.folder_open : Icons.maximize, color: Colors.white.withOpacity(0.8), size: 25),
                  onPressed: (){
                    setState((){
                      print("menu lateral dir");
                      side_left_menu_is_visible_results = !side_left_menu_is_visible_results;
                    });
                  },
                ),
                Container(
                  width: side_left_menu_is_visible_results ? 210 : 0,
                  child: Visibility(
                      visible: side_left_menu_is_visible_results,
                      child: Column(
                        children: [
                          for(int i=0; i<5; i++)
                            Container(
                              margin: EdgeInsets.all(5),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shadowColor: Colors.transparent.withOpacity(0.1),
                                  side: const BorderSide(
                                    width: 1,
                                    color: Colors.grey,
                                  ),
                                  elevation: 5,
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Column(
                                      children: [
                                        Text(i == 0 ? 'Melhor Indivíduo' : '${i+1}° Melhor Indivíduo', style: TextStyle(color: Colors.white, fontSize: 14),),
                                        SizedBox(height: 5,),
                                        Text(rankedsolutions.isNotEmpty ? 'Precisão: ${(rankedsolutions[i].accuracy).toStringAsFixed(2)}, Massa: ${(rankedsolutions[i].weight).toStringAsFixed(2)} Kg' : 'Vazio', style: TextStyle(color: Colors.white, fontSize: 11),),
                                        Text(rankedsolutions.isNotEmpty ? 'Error médio: ${((rankedsolutions[i].vector_errors.sum()/5)*100).toStringAsFixed(2)} %' : 'Vazio', style: TextStyle(color: Colors.white, fontSize: 11),),
                                      ],
                                    )
                                ),
                                onPressed: () {
                                  print('selecting individual on results');
                                  setState(() {
                                    individual_select = i;
                                  });
                                },
                              ),
                            )
                        ],
                      )
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 53,
                child: Container(
                  margin: EdgeInsets.only(top: 30, left: 30, right: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(alignment: Alignment.center,child: Text('Parâmetros', style: TextStyle(color: Colors.white, fontSize: 18),)),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4,),
                              Text(rankedsolutions.isEmpty ? 'Vazio' : 'Precisão: ${rankedsolutions[individual_select].accuracy.toStringAsFixed(2)}', style: TextStyle(color: Colors.white),),
                              Text(rankedsolutions.isEmpty ? 'Vazio' : 'Massa: ${rankedsolutions[individual_select].weight.toStringAsFixed(2)} Kg', style: TextStyle(color: Colors.white),),
                              Text(rankedsolutions.isEmpty ? 'Vazio' : 'Frequência desejada: [${(dumper.freq[0]).toStringAsFixed(1)}, ${(dumper.freq[1]).toStringAsFixed(1)}, ${(dumper.freq[2]).toStringAsFixed(1)}, ${(dumper.freq[3]).toStringAsFixed(1)}, ${(dumper.freq[4]).toStringAsFixed(1)}] Hz', style: TextStyle(color: Colors.white),),
                              Text(rankedsolutions.isEmpty ? 'Vazio' : 'Frequência obtida:     [${(rankedsolutions[individual_select].vector_ans[0]).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_ans[1]).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_ans[2]).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_ans[3]).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_ans[4]).toStringAsFixed(1)}] Hz', style: TextStyle(color: Colors.white),),
                              Text(rankedsolutions.isEmpty ? 'Vazio' : 'Erro por frequência:   [${(rankedsolutions[individual_select].vector_errors[0]*100).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_errors[1]*100).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_errors[2]*100).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_errors[3]*100).toStringAsFixed(1)}, ${(rankedsolutions[individual_select].vector_errors[4]*100).toStringAsFixed(1)}] %', style: TextStyle(color: Colors.white),),
                              Text(rankedsolutions.isEmpty ? 'Vazio' : 'Erro médio: ${((rankedsolutions[individual_select].vector_errors.sum()/5)*100).toStringAsFixed(2)}%', style: TextStyle(color: Colors.white),),
                              Text('Largura: ${(dumper.lenght*100).toStringAsFixed(1)} mm', style: TextStyle(color: Colors.white),),
                              Text('Comprimento: ${(dumper.width*1000).toStringAsFixed(1)} cm', style: TextStyle(color: Colors.white),),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 350,
                        height: 200,
                        child: SelectChart('errors_by_freq_radar', current_width, current_height, false, individual_select)
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 47,
                child: Container(
                  width: 560,
                  height: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Dimensionamento do atenuador',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Roboto',
                            fontStyle: FontStyle.italic,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      SizedOverflowBox(
                        size: Size(200, 70),
                        child: Container(
                            height: 90,
                            child: Image.asset('images/perfil_trilho_1.png', )
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IgnorePointer(
                            ignoring: true,
                            child: Container(
                                margin: EdgeInsets.only(left: 85.2),
                                width: 32,
                                height: 90,
                                child: Image.asset('images/perfil_trilho_2.png')
                            ),
                          ),
                          SizedOverflowBox(
                            size: Size(440, 100),
                            child: Container(
                              width: 455,
                              height: 110,
                              child: SfCartesianChart(
                                  margin: EdgeInsets.all(0),
                                  borderWidth: 0,
                                  primaryYAxis: NumericAxis(isVisible: false),
                                  primaryXAxis: NumericAxis(isVisible: false),
                                  plotAreaBorderWidth: 0,
                                  borderColor: Colors.transparent,
                                  tooltipBehavior: rankedsolutions.isNotEmpty ? _tooltipBehaviorThickness('Espessura', rankedsolutions[individual_select]) : null,
                                  series: <ChartSeries>[
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4)),
                                        dataSource: chartData,
                                        color: Colors.white12,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y1
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4) ),
                                        dataSource: chartData,
                                        color: Colors.white70,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y2
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4) ),
                                        dataSource: chartData,
                                        color: Colors.white12,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y3
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4) ),
                                        dataSource: chartData,
                                        color: Colors.white70,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y4
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4) ),
                                        dataSource: chartData,
                                        color: Colors.white12,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y5
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4)),
                                        dataSource: chartData,
                                        color: Colors.white70,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y6
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle,margin: EdgeInsets.all(4)  ),
                                        dataSource: chartData,
                                        color: Colors.white12,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y7
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4) ),
                                        dataSource: chartData,
                                        color: Colors.white70,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y8
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4) ),
                                        dataSource: chartData,
                                        color: Colors.white12,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y9
                                    ),
                                    StackedBarSeries<ChartData, num>(
                                        animationDuration: 500,
                                        dataLabelSettings: DataLabelSettings(isVisible:true, color: Colors.black, labelAlignment: ChartDataLabelAlignment.middle, margin: EdgeInsets.all(4) ),
                                        dataSource: chartData,
                                        color: Colors.white70,
                                        borderColor: Colors.white70,
                                        borderWidth: 1,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8), bottomRight: Radius.circular(8),
                                        ),
                                        xValueMapper: (ChartData data, _) => data.x,
                                        yValueMapper: (ChartData data, _) => data.y10
                                    ),
                                  ]
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedOverflowBox(
                        size: Size(200, 30),
                        child: Container(
                            width: 200,
                            height: 55,
                            child: Image.asset('images/perfil_trilho_3.png', )
                        ),
                      ),
                      SizedBox(height: 4,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            color: Colors.white12,
                          ),
                          SizedBox(width: 8,),
                          Text('Borracha', style: TextStyle(color: Colors.white, fontSize: 10),),
                          SizedBox(width: 30,),
                          Container(
                            width: 15,
                            height: 15,
                            color: Colors.white70,
                          ),
                          SizedBox(width: 8,),
                          Text('Aço', style: TextStyle(color: Colors.white, fontSize: 10),)
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      oneTimeAfterEnd = 0;

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
                          //botões play/pause/cancel
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
                                    pauseOneTime=0;
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
                                    // if(generation < VIEW_INTERVAL){
                                    //   minViewChart = 1;
                                    //   maxViewChart = generation.toDouble();
                                    // }else{
                                    //   minViewChart = (generation-VIEW_INTERVAL).toDouble();
                                    //   maxViewChart = generation.toDouble();
                                    // }
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
                    OverViewPage(currentWidth, currentHeight),
                    ResultsPage(currentWidth, currentHeight, individual_select),
                  ],
                )),
            //rodapé
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
                      child: Text(
                        ((){
                          String statustxt = '';
                          if(algorithm_status == STATUS_IN_PROCESS){
                            statustxt = 'Em progresso.';
                          }if(algorithm_status == STATUS_SUCESSFULL){
                            statustxt = 'Finalizado com sucesso.';
                          }if(algorithm_status == STATUS_FINISHED){
                            statustxt = 'Limite de gerações atingido';
                          }if(algorithm_status == STATUS_PAUSE){
                            statustxt = 'Pausado';
                          }if(algorithm_status == STATUS_STOP){
                            statustxt = 'Cancelado';
                          }if(algorithm_status == STATUS_ERROR2){
                            statustxt = 'Erro 400 - parâmetros muito limitados ou conflitantes';
                          }if(algorithm_status == STATUS_ERROR3){
                            statustxt = 'Erro 401 - geração nula';
                          }
                          //média de uma geração: ${(averageExecutionTime/1000).toStringAsFixed(0)}ms
                          if(currentWidth > 900){
                            return 'Geração: $generation. Tempo de execução: ${printTimeFromMicroseconds(currentExecutionTime)}, média de uma geração: ${(averageExecutionTime/1000).toStringAsFixed(0)}ms, status: $statustxt';
                          }else{
                            return 'Geração: $generation. Tempo de execução: ${printTimeFromMicroseconds(currentExecutionTime)}, status: $statustxt';
                          }
                        }()),
                        style: TextStyle(color: Colors.white, fontSize: 12),),
                    ),
                  ),
                  const SizedBox(width: 24,)
                ],
              )
            ],),
          ]
        ),
      )
    );
  }
}

class ChartData{
  ChartData(this.x, this.y1, this.y2, this.y3, this.y4, this.y5, this.y6, this.y7, this.y8, this.y9, this.y10);
  final double x;
  final double y1;
  final double y2;
  final double y3;
  final double y4;
  final double y5;
  final double y6;
  final double y7;
  final double y8;
  final double y9;
  final double y10;
}
class GraphData{
  final double x;
  final double y;
  GraphData(this.x, this.y);
}
class GraphDataColumn{
  final String x;
  final double y;
  GraphDataColumn(this.x, this.y);
}

String printTimeFromMicroseconds(int time){
  if(time < 1000){
    return "${time.toStringAsFixed(2)}us";
  }else if (time < 1000000){
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

