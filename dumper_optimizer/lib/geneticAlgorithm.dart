import 'dart:math';
import 'dart:core';
import 'package:data/data.dart';

import 'v1_0_fisics_dumper.dart';

class Individual{
  double accuracy;
  List<List<double>> rigidez; //(L,C,t,E)
  List<List<double>> aco; //(L,C,t)
  List<double> vector_errors;
  List<double> vector_ans;
  List<List<double>> genesis_rigidez_mm; //Ex de medidas: [6.3, 8.0] -> [[3.0, 3.3], [3.0, 5.0]]
  List<List<double>> genesis_aco_mm; //O mesmo para o de cima
  double weight;

  Individual(this.accuracy, this.rigidez, this.aco, this.vector_errors, this.vector_ans, this.genesis_rigidez_mm, this.genesis_aco_mm, this.weight);
}

int expovariate(int n){
  Random random = Random();
  int randomNumber = random.nextInt(n);
  //print(randomNumber/n);
  var x = log(1-(randomNumber/n))/(-5);
  print(x);
  return (x*n).toInt();
}
List<Object> select_thickness(List<double> vector_mm){
  Random random = Random();
  int times = random.nextInt(3);
  double answer = 0.0;
  List<double> formation_mm = [];
  for(int i=0; i<=times; i++){
    int choice = random.nextInt(vector_mm.length);
    answer += vector_mm[choice]/1000;
    formation_mm.add(vector_mm[choice]);
  }
  answer = double.parse(answer.toStringAsFixed(6)); //removing bug of the accuracy
  var final_answer = [answer, formation_mm];
  return final_answer;
}

//não foi testado
List<Object> fitness(List<List<double>> aco, List<List<double>> rigidez, List<double> correct_ans, Dumper arg) {
  double error = 0;
  //Limitation of weight values part
  double total_weight = weight_calculate(aco, rigidez, arg);
  if (total_weight < arg.min_weight || total_weight > arg.max_weight){
    error = pow(10.0, 10) as double;
  }
  //Limitation of thickness values part
  for(final _aco in aco){
    if(_aco[2] < arg.min_massThickness_mm/1000 || _aco[2] > arg.max_massThickness_mm/1000){
      error = pow(10.0, 10) as double;
    }
  }
  for (final _rigidez in rigidez){
    if(_rigidez[2] < arg.min_springThickness_mm/1000 || _rigidez[2] > arg.max_springThickness_mm/1000){
      error = pow(10.0, 10) as double;
    }
  }
  if(error != 0){
    return [0.0, [1, 1, 1, 1, 1], [0, 0, 0, 0, 0]];
  }

  List<double> ans = main_dumper_freq(aco, rigidez, arg);
  ans.sort((b, a) => a.compareTo(b)); //for sorting ascending
  List<double> vector_error = [((ans[0]-correct_ans[0])/correct_ans[0]), ((ans[1]-correct_ans[1])/correct_ans[1]), ((ans[2]-correct_ans[2])/correct_ans[2]), ((ans[3]-correct_ans[3])/correct_ans[3]), ((ans[4]-correct_ans[4])/correct_ans[4])];
  for(int i=0 ;i<ans.length; i++){
    vector_error[i] = vector_error[i].abs();
  }
  List<double> weight = [2, 3, 4, 5, 1];
  error = (vector_error[0]*weight[0] + vector_error[1]*weight[1] + vector_error[2]*weight[2] + vector_error[3]*weight[3] + vector_error[4]*weight[4])/weight.sum();
  if (error == 0) {
    return [pow(10.0, 10) as double,[0, 0, 0, 0, 0] , [1, 1, 1, 1, 1]];
  }
  return [(1/error).abs(), vector_error, ans];
}

List<Individual> generate_new_solution(int generation_size, Dumper arg){
  List<Individual> first_generation = [];//vector of [[thickness itself (double), genesis List<double>]5x]

  for(int i=0; i<generation_size;i++){
    late Individual ind;
    List<List<double>> _genesis_aco_mm = [];
    List<List<double>> _genesis_rigidez_mm = [];
    List<List<double>> _aco = [];
    List<List<double>> _rigidez = [];
    for(int i=0; i<5;i++){
      var aco_thickness = select_thickness(arg.massOptions);
      var rigidez_thickness = select_thickness(arg.springOptions);
      _genesis_aco_mm.add(aco_thickness[1] as List<double>);
      _genesis_rigidez_mm.add(rigidez_thickness[1] as List<double>);
      _aco.add([arg.lenght, arg.width, aco_thickness[0] as double]);
      _rigidez.add([arg.lenght, arg.width, rigidez_thickness[0] as double, arg.springElasticity]);
    }
    double _weight = weight_calculate(_aco, _rigidez, arg);
    ind = Individual(0, _rigidez, _aco, [0, 0, 0, 0, 0], [1, 1, 1, 1, 1], _genesis_rigidez_mm, _genesis_aco_mm, _weight);
    first_generation.add(ind);
  }

  return first_generation;
}

List<Object> selection_function(List<Individual> population, List<double> correct_ans, int limit_generations, int generation_size){
  List<Individual> population = [];
  int status = 0;
  List<Object> return_answer = [population, status];
  return return_answer;
}

//or List<Objet>