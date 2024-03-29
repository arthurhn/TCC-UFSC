import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dumper_optimizer/v1_0_fisics_dumper.dart';
import 'package:flutter/material.dart';
import 'formPage.dart';


void main(){
  runApp(MyApp());
  doWhenWindowReady(() {
    // var initialSize = Size(1280, 720);
    var initialSize = Size(1150, 650);
    appWindow.size = initialSize;
    appWindow.minSize = Size(700, 650);
    appWindow.show();
  });
}


class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  Dumper dumper = Dumper(
  0,  [2, 2, 2, 2, 10], [2, 3, 4, 5, 1], 50/1000, 490/1000, 4, 11, 2, 15, 3, 15,
  [2, 3, 4], [3, 3.3, 3.8, 5], 7800, 1300, 3.5*pow(10, 6),
  [1863.0, 1470.0, 1034.0, 603.0, 360.0], 300, 250, 50);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FormPage(dumper: dumper,),
    );
  }
}
