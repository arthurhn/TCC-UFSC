import 'dart:math';
import 'dart:core';
import 'package:data/data.dart';
import 'package:dumper_optimizer/home.dart';
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

  // .from Constructor for copying
  factory Individual.from(Individual objectA){

    List<List<double>> rigidez = [];
    for(int i=0; i<objectA.rigidez.length; i++){
      rigidez.add(List<double>.from(objectA.rigidez[i]));
    }
    List<List<double>> aco = [];
    for(int i=0; i<objectA.aco.length; i++){
      aco.add(List<double>.from(objectA.aco[i]));
    }
    List<List<double>> genesis_rigidez_mm = [];
    for(int i=0; i<objectA.genesis_rigidez_mm.length; i++){
      genesis_rigidez_mm.add(List<double>.from(objectA.genesis_rigidez_mm[i]));
    }
    List<List<double>> genesis_aco_mm = [];
    for(int i=0; i<objectA.genesis_aco_mm.length; i++){
      genesis_aco_mm.add(List<double>.from(objectA.genesis_aco_mm[i]));
    }

    return Individual(objectA.accuracy, rigidez, aco,
        List<double>.from(objectA.vector_errors), List<double>.from(objectA.vector_ans), genesis_rigidez_mm,
        genesis_aco_mm, objectA.weight);
  }

  Individual(this.accuracy, this.rigidez, this.aco, this.vector_errors, this.vector_ans, this.genesis_rigidez_mm, this.genesis_aco_mm, this.weight);
}

//funções auxiliares
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
int count_usefull_solution(List<Individual> population){
  int usefull_solutions = 0;
  for(int i=0;i<population.length; i++){
    if(population[i].accuracy != 0){
      usefull_solutions++;
    }
  }
  return usefull_solutions;
}
Individual rate_individual(Individual ind, Dumper arg){
  List<Object> fit = fitness(ind.aco, ind.rigidez, arg.freq, arg);
  ind.accuracy = fit[0] as double;
  ind.vector_errors = fit[1] as List<double>;
  ind.vector_ans= fit[2] as List<double>;
  return ind;
}
bool individual_on_list(Individual ind, List<Individual> population){

  if(population.isEmpty){
    return false;
  }
  for(int i=0; i<population.length;i++){
    int aco_count = 0;
    int rigidez_count = 0;
    for(int j=0; j<5;j++){
      if(population[i].rigidez[j][2] == ind.rigidez[j][2]){
        rigidez_count++;
      }
      if(population[i].aco[j][2] == ind.aco[j][2]){
        aco_count++;
      }
    }
    if(aco_count == 5 && rigidez_count == 5){
      return true;
    }
  }
  return false;
}

List<Object> fitness(List<List<double>> aco, List<List<double>> rigidez, List<double> correct_ans, Dumper arg) {
  double error = 0;
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
    return [0.0, [0.0, 0.0, 0.0, 0.0, 0.0] , [1.0, 1.0, 1.0, 1.0, 1.0]];
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
    return [pow(10.0, 10) as double,[0.0, 0.0, 0.0, 0.0, 0.0] , [1.0, 1.0, 1.0, 1.0, 1.0]];
  }
  return [(1/error).abs(), vector_error, ans];
}

//ele pode criar individuos repetidos, é cargo do selection remover
//usado tanto pra criar a primeira lista de individuos, como para criar um individuo aleatório, baste generation_size=1
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
    //pode adicionar já que ele passou pelo while, logo não é repetido
    first_generation.add(ind);
  }
  return first_generation;
}

//a ideia aqui é um pouco diferente do que acontece no python, aqui já recebemos os individuos como um objeto,
//logo, ele apenas seleciona e retorna os 10 melhores em ordem e retorna o status do algoritmo, é ele quem vai dizer se um individuo atende os requisitos ou não
//em outras palavras, é ele que vai dar o status de sucesso
List<Object> selection_function(List<Individual> population, List<double> correct_ans, Dumper arg, int limit_generations, int generation_size)      {
  List<Individual> rankedsolutions = [];
  List<Individual> allsolutions = [];
  int selection_status = STATUS_IN_PROCESS;
  if(population.isEmpty){
    print("select_function: STATUS_ERROR3");
    selection_status = STATUS_ERROR3;
    return [rankedsolutions, selection_status, allsolutions];
  }


  //avaliando a população e colocando o weight, preciso fazer isso pq na primeira iteração por exemplo a precisão não esta definida, e nem pode pq n sabe o freq_target
  for(int i=0; i<population.length;i++){
    population[i] = rate_individual(population[i], arg);
    population[i].weight = weight_calculate(population[i].aco, population[i].rigidez, arg);
  }

  int usefull_solutions = count_usefull_solution(population);

  int generateTimes = 0;
  // verificando se há soluções que atendem aos requisitos
  while(usefull_solutions < 10 && generateTimes < 1000){
    generateTimes++;//limitador só pra ele n ficar travando o código, mas em teoria que q tirar, eu colocar um valor mt alto pra caso ele chegue aqui, o status retone um warning

    // Individual old_individual = population[0];//salvando individuo que vai ser excluido
    //as próximas linhas de código é ele tirando um individuo que não se adaquava nos requisitos e adicionando um novo aleatório
    for(int i=0; i<population.length;i++){
      if(population[i].accuracy == 0){
        population.removeAt(i);
        break;
      }
    }
    Individual new_individual = generate_new_solution(1, arg)[0];
    new_individual = rate_individual(new_individual, arg);

    //Verificando se o individuo não é repetido (se ele já existe aqui) antes de de fato adicionar
    bool previus_exists = individual_on_list(new_individual, population);
    if(!previus_exists){
      population.add(new_individual);
    }

    usefull_solutions = count_usefull_solution(population);
  }
  if(usefull_solutions < 10){
    print("select_function: STATUS_ERROR2");
    selection_status = STATUS_ERROR2;
    return [rankedsolutions, selection_status, allsolutions];
  }

  //-------------------------------------------------------------

  List<Individual> rankedsolutions_sort = [];
  //aqui "começa a selection", antes era só verificação se tinha 10 individuos válidos de acordo com os requisitos
  int n = population.length;
  for(int i=0; i<n;i++){
    Individual best_from_population = Individual.from(population[0]);
    int position_of_the_best = 0;
    for(int j=0; j<population.length;j++){
      if(population[j].accuracy > best_from_population.accuracy){
        best_from_population = Individual.from(population[j]);
        position_of_the_best = j;
      }
    }
    bool already_exist = individual_on_list(best_from_population, rankedsolutions_sort);
    if(!already_exist){
      rankedsolutions_sort.add(best_from_population);
    }else{
    }
    population.removeAt(position_of_the_best);
  }
  for(int i=0; i<rankedsolutions_sort.length;i++){
    allsolutions.add(Individual.from(rankedsolutions_sort[i]));
  }

  rankedsolutions_sort = rankedsolutions_sort.take(10).toList();

  if(rankedsolutions_sort.isEmpty){
    print("select_function: STATUS_ERROR3");
    return [rankedsolutions, 3, allsolutions];
  }
  List<double> _best_error = rankedsolutions_sort[0].vector_errors;

  var best_error = List.of(_best_error);
  for(int i=0; i<best_error.length;i++){
    best_error[i] = double.parse((best_error[i]*100).toStringAsFixed(2));
  }

  if  (best_error[0] < arg.freq_error[0] && best_error[1] < arg.freq_error[1] && best_error[2] < arg.freq_error[2] && best_error[3] < arg.freq_error[3] && best_error[4] < arg.freq_error[4]){
    return [rankedsolutions_sort, STATUS_SUCESSFULL, allsolutions];
  }

  List<Object> return_answer = [rankedsolutions_sort, STATUS_IN_PROCESS, allsolutions];
  return return_answer;
}

//ainda tem q verificar se os crossover não são repetidos
List<Individual> crossover_function(List<Individual> topsolutions, Dumper arg){
  List<Individual> crossover_solution = [];
  if(topsolutions.isEmpty){
    return crossover_solution;
  }

  for(int i=0; i<10;i++){//O ESSE NÚMERO DE 10 INDIVIDUOS CRIADO VIA CROSSOVER PODE SER VARIÁVEL
    int who_is_change = Random().nextInt(3); //0 -> just rigidez will change, 1 -> just aco, 2 -> both
    int how_many_try_changes = Random().nextInt(4)+1;
    int chosen_position = Random().nextInt(10);
    int chosen_position2 = Random().nextInt(10);
    while (chosen_position2 == chosen_position){
      chosen_position2 = Random().nextInt(10);
    }
    //selecting both solution to compare
    Individual ind = topsolutions[chosen_position]; //solution that will be add to crossover_solution
    Individual ind2 = topsolutions[chosen_position2];

    if(who_is_change == 0){
      for(int i=0; i<how_many_try_changes;i++){
        int change_position = Random().nextInt(5);
        ind.rigidez[change_position][2] = ind2.rigidez[change_position][2];
        ind.genesis_rigidez_mm = List<List<double>>.from(ind2.genesis_rigidez_mm);
      }
    }
    if(who_is_change == 1){
      for(int i=0; i<how_many_try_changes;i++){
        int change_position = Random().nextInt(5);
        ind.aco[change_position][2] = ind2.aco[change_position][2];
        ind.genesis_aco_mm = List<List<double>>.from(ind2.genesis_aco_mm);
      }
    }
    if(who_is_change == 2){
      for(int i=0; i<how_many_try_changes;i++){
        int change_position = Random().nextInt(5);
        ind.rigidez[change_position][2] = ind2.rigidez[change_position][2];
        ind.genesis_rigidez_mm = List<List<double>>.from(ind2.genesis_rigidez_mm);
      }
      how_many_try_changes = Random().nextInt(4)+1;
      for(int i=0; i<how_many_try_changes;i++){
        int change_position = Random().nextInt(5);
        ind.aco[change_position][2] = ind2.aco[change_position][2];
        ind.genesis_aco_mm = List<List<double>>.from(ind2.genesis_aco_mm);
      }
    }

    crossover_solution.add(ind);
  }
  return crossover_solution;
}

List<Individual> mutation_function(List<Individual> rankedsolutions, int generation_size, Dumper arg){
  List<Individual> mutation_list = [];
  List<Individual> new_population = [];//list that will return with rankedsolutions + new_population

  if(rankedsolutions.isEmpty){
    return new_population;
  }

  for(int j=0; j<rankedsolutions.length;j++){
    new_population.add(rankedsolutions[j]);
  }

  if(generation_size-rankedsolutions.length <= 0){
    print("Limit generation muito baixo ou rankedsolution muito alto");
    return new_population;
  }
  for(int i=0; i<generation_size-rankedsolutions.length;i++){
    //dado o vector concatenado solutions, o valor de i que é quem vai escolher o individuo a ser mutado para criar um novo,
    int i = Random().nextInt(rankedsolutions.length);
    //------------------------------------------------------------------------------------------
    int how_is_change = Random().nextInt(3); //0 -> only rigidez will change, 1 -> only aco, 2 -> both
    int how_many_try_change = Random().nextInt(5)+1;
    Individual new_individual = Individual.from(rankedsolutions[i]);

    // print("\nhow_is_change: $how_is_change, how_many_try_change: $how_many_try_change");
    if(how_is_change == 0){
      for(int j=0; j<how_many_try_change;j++){
        int change_position = Random().nextInt(5);
        List<Object> aux_rigidez = select_thickness(arg.springOptions);
        new_individual.rigidez[change_position][2] = aux_rigidez[0] as double;
        new_individual.genesis_rigidez_mm[change_position] = aux_rigidez[1] as List<double>;
      }
    }
    if(how_is_change == 1){
      for(int j=0; j<how_many_try_change;j++){
        int change_position = Random().nextInt(5);
        List<Object> aux_aco = select_thickness(arg.massOptions);
        new_individual.aco[change_position][2] = aux_aco[0] as double;
        new_individual.genesis_aco_mm[change_position] = aux_aco[1] as List<double>;
      }
    }
    if(how_is_change == 2){
      for(int j=0; j<how_many_try_change;j++){
        int change_position = Random().nextInt(5);
        List<Object> aux_rigidez = select_thickness(arg.springOptions);
        new_individual.rigidez[change_position][2] = aux_rigidez[0] as double;
        new_individual.genesis_rigidez_mm[change_position] = aux_rigidez[1] as List<double>;
      }
      how_many_try_change = Random().nextInt(5)+1;
      for(int j=0; j<how_many_try_change;j++){
        int change_position = Random().nextInt(5);
        List<Object> aux_aco = select_thickness(arg.massOptions);
        new_individual.aco[change_position][2] = aux_aco[0] as double;
        new_individual.genesis_aco_mm[change_position] = aux_aco[1] as List<double>;
      }
    }

    mutation_list.add(new_individual);
  }

  for(int j=0; j<mutation_list.length;j++){
    new_population.add(mutation_list[j]);
  }
  return new_population;
}

double select_pressure(List<Individual> population){
  if(population.length == 0){
    return 1.0;
  }

  double ps=0.0;
  List<double> vector_accuracy = [];
  Individual best = Individual.from(population[0]);
  for(int i=0;i<population.length;i++){
    if(population[i].accuracy != 0){
      vector_accuracy.add(population[i].accuracy);
    }
  }
  double average_accuracy = vector_accuracy.average();
  double g0 = 1/best.accuracy;
  double g = 1/average_accuracy;
  ps = g0/g;
  return ps;
}
