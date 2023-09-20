import 'dart:math';
import 'package:ml_linalg/linalg.dart';
import 'package:ml_linalg/matrix.dart' as ma;
import 'package:data/data.dart' as da;
import 'dart:core';

class Dumper{
  List<double> freq; //[Hz]
  List<double> freq_error; //[%]
  double width; //[m]
  double lenght; //[m]
  double min_weight; //[Kg]
  double max_weight; //[Kg]
  double min_springThickness_mm; //[mm]
  double max_springThickness_mm; //[mm]
  double min_massThickness_mm; //[mm]
  double max_massThickness_mm; //[mm]
  List<double> springOptions; //[mm]
  List<double> massOptions; //[mm]
  double massDensity; //[Kg/m^3]
  double springDensity; //[Kg/m^3]
  double springElasticity; //[Pa]
  int count;

  Dumper(this.count, this.freq, this.freq_error, this.width, this.lenght, this.min_weight, this.max_weight,
      this.min_springThickness_mm, this.max_springThickness_mm, this.min_massThickness_mm, this.max_massThickness_mm,
      this.springOptions, this.massOptions, this.massDensity, this.springDensity, this.springElasticity);
}

List<List<List<double>>> parametros(List<double> tmola, List<double> taco, Dumper arg){
  List<List<double>> rigidez = [];
  List<List<double>> aco = [];
  for(int i=0; i < tmola.length; i++){
    rigidez.add([arg.lenght, arg.width, tmola[i], arg.springElasticity]);
  }
  for(int i=0; i < taco.length; i++){
    aco.add([arg.lenght, arg.width, taco[i]]);
  }
  List<List<List<double>>> response = [rigidez, aco];
  return response;
}

List<List<double>> calculaRigMass(List<List<double>> dim_mass, List<List<double>> dim_rig, Dumper arg){
  int row_mass = dim_mass.length;
  List<double> k = List.filled(row_mass, 0);
  List<double> m = List.filled(row_mass, 0);
  for(int a=0; a<=row_mass-1;a++){
    k[a] = dim_rig[a][0]*dim_rig[a][1]*dim_rig[a][3]/dim_rig[a][2];
    m[a] = dim_mass[a][0]*dim_mass[a][1]*dim_mass[a][2]*arg.massDensity + dim_rig[a][0]*dim_rig[a][1]*dim_rig[a][2]*arg.springDensity;
  }
  List<List<double>> response = [k, m];
  // print('[k]: $k \n [m]: $m!');
  return response;

}

List<List<List<double>>> criaMatrizes(List<List<double>> dados){
  List<double> m = dados[1];
  List<double> k = dados[0];

  int n = m.length;
  List<List<double>> M = List.generate(n, (i) => [0, 0, 0, 0, 0]);
  List<List<double>> K = List.generate(n, (i) => [0, 0, 0, 0, 0]);
  for(int a=0; a<n; a++){
    M[a][a] = m[a];
    if (a!=0){
      K[a][a-1] = -k[a];
    }
    if(a==n-1){
      K[a][a] = k[a];
    }else{
      K[a][a] = k[a] + k[a+1];
    }
    if (a!=(n-1)){
      K[a][a+1] = -k[a+1];
    }
  }
  List<List<List<double>>> response = [M, K];
  return response;
}

List<double> freq(List<List<List<double>>> dados){
  List<List<double>> M = dados[0];
  List<List<double>> K = dados[1];
  int n = M.length;
  final matrix = ma.Matrix.fromList(M);
  final inverted = matrix.inverse();
  List<List<double>>  M_1 = [];
  for(int i=0; i<n; i++){
    M_1.add(inverted[i].toList());
  }

  List<List<double>> zero = List.generate(n, (i) => [0, 0, 0, 0, 0]);
  List<List<double>> ident = [];
  var aux = ma.Matrix.identity(n);
  for(int i=0; i<aux.length; i++){
    ident.add(aux[i].toList());
  }
  List<List<double>>  primeira = [];
  for(int i=0; i<n; i++){
    primeira.add([zero[i], ident[i]].expand((x) => x).toList());
  }

  for(int i=0; i<M_1.length; i++){
    for(int j=0; j<M_1[i].length; j++){
      if(M_1[i][j] != 0){
        M_1[i][j] = -1*M_1[i][j];
      }
    }
  }

  final matrix_M_1 = ma.Matrix.fromList(M_1);
  final matrix_K = ma.Matrix.fromList(K);
  final result = matrix_M_1*matrix_K;

  List<List<double>> aux_segunda = [];
  for(int i=0; i<n; i++){
    aux_segunda.add(result[i].toList());
  }

  List<List<double>> segunda = [];
  for(int i=0; i<n; i++){
    segunda.add([aux_segunda[i], zero[i]].expand((x) => x).toList());
  }

  List<List<double>> A = [];
  for(int i=0; i<n*2; i++){
    if(i < n){
      A.add(primeira[i]);
    }else{
      A.add(segunda[i-n]);
    }
  }

  final a = da.Matrix<double>.fromRows(da.DataType.float64, A);
  final decomposition = a.eigenvalue;
  List<double> w = decomposition.imagEigenvalues;

  List<double> f = List.filled(w.length, 0);
  List<double> f_pos = List.filled(w.length~/2, 0);
  int j=0;
  for(int i=0; i<w.length;i++){
    f[i] = w[i]/(2*3.14);
    if (f[i]>0){
      f_pos[j] = f[i];
      j+=1;
    }
  }
  return f_pos;
}

double weight_calculate(List<List<double>> aco, List<List<double>> rigidez, Dumper arg){
  List<double> volume_aco = [];

  for(int i=0; i<aco.length;i++){
    volume_aco.add(aco[i][2]*(arg.lenght) *(arg.width));
  }
  // print("aco no weight: $aco");
  // print("rigidez no weight: $rigidez");
  List<double> volume_rigidez = [];
  for(int i=0; i<rigidez.length;i++){
    volume_rigidez.add(rigidez[i][2]*(arg.lenght) *(arg.width));
  }
  List<double> array_weight_aco = [];
  for(int i=0; i<volume_aco.length;i++){
    array_weight_aco.add(volume_aco[i]*arg.massDensity);
  }
  List<double> array_weight_rigidez = [];
  for(int i=0; i<volume_rigidez.length;i++){
    array_weight_rigidez.add(volume_rigidez[i]*arg.springDensity);
  }
  double total_weight = array_weight_aco.sum()+array_weight_rigidez.sum();
  return total_weight;
}

List<double> main_dumper_freq(List<List<double>> aco, List<List<double>> rigidez, Dumper arg){

  // print("main");
  // print(aco);
  // print(rigidez);
  List<double> f = freq(criaMatrizes(calculaRigMass(aco, rigidez, arg)));
  return f;
}
