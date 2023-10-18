import 'package:dumper_optimizer/home.dart';
import 'package:dumper_optimizer/v1_0_fisics_dumper.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'main.dart';

class AnimationSection{
  double height_max;
  bool visibility;
  String label;
  AnimationSection(this.height_max, this.visibility, this.label);
}

class FormPage extends StatefulWidget {
  Dumper dumper;
  FormPage({Key? key, required this.dumper}) : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState(dumper);
}

class _FormPageState extends State<FormPage> {
  late Dumper dumper;
  _FormPageState(this.dumper);
  GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  @override
  bool delay = false;//serve verificar se a animação das seções esta ocorrendo, caso sim, o conteúdo da seção permanece escondido para não dar overflow
  AnimationSection springOptionsThickness = AnimationSection(0.0, false, 'Opções de mola');
  AnimationSection massOptionsThickness = AnimationSection(0.0, false, 'Opções de aço');
  double inputmax = 70; //numero padrão que um formtext tem
  late double qtd_massOp;
  late double qtd_springOp;
  bool advancedOptionsIsVisible = false;


  void onWriting_form(Dumper _dumper, String _field, String? value){
    if(_formkey.currentState!.validate()){
      if(value != null){
        // print("Formulário ok!");
        setState((){
          if(_field == 'freq[0]'){
            _dumper.freq[0] = double.parse(value);
          }else if(_field == 'freq[1]'){
            _dumper.freq[1] = double.parse(value);
          }else if(_field == 'freq[2]'){
            _dumper.freq[2] = double.parse(value);
          }else if(_field == 'freq[3]'){
            _dumper.freq[3] = double.parse(value);
          }else if(_field == 'freq[4]'){
            _dumper.freq[4] = double.parse(value);
          }else if(_field == 'freq_error[0]'){
            _dumper.freq_error[0] = double.parse(value);
          }else if(_field == 'freq_error[1]'){
            _dumper.freq_error[1] = double.parse(value);
          }else if(_field == 'freq_error[2]'){
            _dumper.freq_error[2] = double.parse(value);
          }else if(_field == 'freq_error[3]'){
            _dumper.freq_error[3] = double.parse(value);
          }else if(_field == 'freq_error[4]'){
            _dumper.freq_error[4] = double.parse(value);
          }else if(_field == 'freq_weight[0]'){
            _dumper.freq_weight[0] = double.parse(value);
          }else if(_field == 'freq_weight[1]'){
            _dumper.freq_weight[1] = double.parse(value);
          }else if(_field == 'freq_weight[2]'){
            _dumper.freq_weight[2] = double.parse(value);
          }else if(_field == 'freq_weight[3]'){
            _dumper.freq_weight[3] = double.parse(value);
          }else if(_field == 'freq_weight[4]'){
            _dumper.freq_weight[4] = double.parse(value);
          }else if(_field == 'width'){
            _dumper.width = double.parse(value)/1000;
          }else if(_field == 'lenght'){
            _dumper.lenght = double.parse(value)/1000;
          }else if(_field == 'springDensity'){
            _dumper.springDensity = double.parse(value);
          }else if(_field == 'springElasticity'){
            _dumper.springElasticity = double.parse(value)*pow(10, 6);
          }else if(_field == 'massDensity'){
            _dumper.massDensity = double.parse(value);
          }else if(_field == 'limitGeneration'){
            _dumper.limit_generation = int.parse(value);
          }else if(_field == 'generationSize'){
            _dumper.generation_size = int.parse(value);
          }else if(_field == 'viewInterval'){
            _dumper.view_interval = int.parse(value);
          }
          for(int i=0; i<10; i++){
            if(_field == 'springOptions[$i]'){
            _dumper.springOptions[i] = double.parse(value);
            }
            if(_field == 'massOptions[$i]'){
              _dumper.massOptions[i] = double.parse(value);
            }
          }
        });
      }
    }
  }

  String? validatorFreq(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 10 || double.parse(value) > 20000){
      return "*Fora do intervalo [10, 20000] Hz";
    }else{
      return null;
    }
  }

  String? validatorFreq_error(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 0 || double.parse(value) > 100){
      return "*Fora do intervalo [0, 100] %";
    }else{
      return null;
    }
  }

  String? validatorFreq_weight(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 0.1 || double.parse(value) > 100){
      return "*Fora do intervalo [0.1, 100] %";
    }else{
      return null;
    }
  }

  String? validatorWidth(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 45 || double.parse(value) > 55){
      return "*Valor fora do intervalo [45, 55] mm";
    }else{
      return null;
    }
  }

  String? validatorLenght(String? value)  {
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 400 || double.parse(value) > 600){
      return "*Valor fora do intervalo [400, 6000] mm";
    }else{
      return null;
    }

  }

  String? validatorElasticity(String? value){
      if(value == null ) {
        return "*Valor inválido";
      }else if(value.isEmpty || double.parse(value) < 0.1 || double.parse(value) > 100){
        return "*Valor fora do intervalo [0.1, 100] MPa";
      }else{
        return null;
      }
    }

  String? validatorDensity(String? value){
      if(value == null ) {
        return "*Valor inválido";
      }else if(value.isEmpty || double.parse(value) < 100 || double.parse(value) > 20000){
        return "*Valor fora do intervalo [100, 20000] Kg/m^3";
      }else{
        return null;
      }
    }

  String? validatorLimitGeneration(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 10 || double.parse(value) > 20000){
      return "*Valor fora do intervalo [10, 20000] gerações";
    }else{
      return null;
    }
  }

  String? validatorGenerationSize(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 10 || double.parse(value) > 2000){
      return "*Valor fora do intervalo [10, 2000] indivíduos";
    }else{
      return null;
    }
  }

  String? validatorViewInterval(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 10 || double.parse(value) > 1000){
      return "*Valor fora do intervalo [10, 1000] indivíduos";
    }else{
      return null;
    }
  }

  String? validatorThickness(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 0.1 || double.parse(value) > 10){
      return "*Valor fora do intervalo [0.1, 10] mm";
    }else{
      return null;
    }
  }

  String? validatorQtdOp(String? value){
    if(value == null ) {
      return "*Valor inválido";
    }else if(value.isEmpty || double.parse(value) < 0.1 || double.parse(value) > 10){
      return "*Valor inválido";
    }else{
      return null;
    }
  }


  Widget build(BuildContext context) {


    // print("formPage");
    // print("massDensity: ${dumper.massDensity}");
    // print("springDensity: ${dumper.springDensity}");
    final currentWidth = MediaQuery.of(context).size.width;
    final currentHeight = MediaQuery.of(context).size.height;

    if(dumper.count == 0){
      dumper.count++;
    }

    qtd_massOp = dumper.massOptions.length.toDouble();
    qtd_springOp = dumper.springOptions.length.toDouble();
    int qtd_massOp_aux = dumper.massOptions.length;
    int qtd_springOp_aux = dumper.springOptions.length;
    SfRangeValues _rangeSlider_weight = SfRangeValues(dumper.min_weight, dumper.max_weight);
    SfRangeValues _rangeSlider_spring_thickness = SfRangeValues(dumper.min_springThickness_mm, dumper.max_springThickness_mm);
    SfRangeValues _rangeSlider_mass_thickness = SfRangeValues(dumper.min_massThickness_mm, dumper.max_massThickness_mm);

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

    Widget formTheme(double _width, String _initialValue, String _labelText, String _hintText, double errorFontSize,  Function _onSumited_form, Function _validator, String field){
      return Container(
        margin: EdgeInsets.only(top: 12),
        width: _width,
        child: TextFormField(
          keyboardType:const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: ((){
            if(field == 'springElasticity'){
              return <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,3}'))];
            }else if(field == 'limitGeneration' || field == 'generationSize' || field == 'viewInterval'){
              return <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^(\d+)'))];
            }else{
              return <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,1}'))];
            }
            return <TextInputFormatter>[_labelText == 'Elasticidade da mola (MPa)' ? FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,3}')) : FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,1}'))];

          }()),
          initialValue: _initialValue,
          decoration: InputDecoration(
            errorStyle: TextStyle(color: Colors.red, fontSize: errorFontSize),
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(10, 22, 22, 10),
            errorBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 0.0),),
            labelText: _labelText,
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 0.0),),
            hintText: _hintText,
            hintStyle: const TextStyle(fontSize: 15.0, color: Colors.grey),
            labelStyle: const TextStyle(color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
          validator: (value){
            return _validator(value);
          },
          onChanged:(value) {
            _onSumited_form(dumper, field, value);
          },
        ),
      );
    }

    Widget animationButton(AnimationSection optionsThickness, _width, String type){
      //numero de seções/de opções dentro do AnimatedContainer
      int qtdElementos = 1;
      String variable_name = '';
      List<double> initialValues = [];
      if(type == 'mass'){
        variable_name = 'massOptions';
        initialValues = dumper.massOptions;
        qtdElementos = dumper.massOptions.length;
      }else{
        variable_name = 'springOptions';
        initialValues = dumper.springOptions;
        qtdElementos = dumper.springOptions.length;
      }
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 30, left: 1, right: 1),
            height: 50,
            width: _width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.only(top: 1, left: 1, right: 1),
                primary: Colors.transparent,
                side: const BorderSide(
                  width: 1,
                  color: Colors.grey,
                ),
                onSurface: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () {
                if(_formkey.currentState!.validate()){
                  setState(() {
                    if(delay){
                      return;
                    }
                    //formdata.data[section].length - 1 é quantos elementos tem essa seção
                    optionsThickness.height_max == (inputmax*qtdElementos)+14 ? optionsThickness.height_max = 0 : optionsThickness.height_max = (inputmax*qtdElementos)+14;
                    delay = true;
                    Future.delayed(const Duration(milliseconds: 250), () { //asynchronous delay
                      if (mounted) { //checks if widget is still active and not disposed
                        setState(() { //tells the widget builder to rebuild again because ui has updated
                          if(optionsThickness.visibility == false){
                            optionsThickness.visibility = true;
                          }
                          delay = false;
                        });
                      }
                    });
                    if(optionsThickness.visibility == true){
                      optionsThickness.visibility = false;
                    }
                  });
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Text(
                      optionsThickness.label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xffffffff),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: optionsThickness.height_max == 0 ? const Icon(Icons.arrow_drop_down_circle_outlined) : Transform.rotate(angle: 3.1415, child: const Icon(Icons.arrow_drop_down_circle_outlined),
                      )),
                ],
              ),
            ),
          ),
          AnimatedContainer (
            duration: const Duration (milliseconds: 200),
            height: optionsThickness.height_max,
            width: _width,
            margin: const EdgeInsets.only(bottom: 1, left: 1, right: 1),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: const Color(0xFFc4c4c4),
                  width: 1,
                )),
            child: Visibility(
              visible: optionsThickness.visibility,
              child: Column(
                children: [
                  for(int j=0; j<qtdElementos; j++)
                    Container(
                        height: 70,
                        child: formTheme(_width, initialValues[j].toString(), 'Opção ${j+1}', 'Ex: ${j+1}', 8, onWriting_form, validatorThickness, '$variable_name[$j]')
                    ),
                ],
              ),
            ),
          ),
        ],
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
                    Expanded(child: MoveWindow()),
                    const WindowButtons()
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //logo
                Container(
                  child: Image(
                    height: 0.2*currentHeight,
                    alignment: Alignment.bottomCenter,
                    image: const AssetImage('images/app_logo.png'),
                  ),
                ),
                //form
                Center(
                  child: Container(
                    height: currentHeight*0.7,
                    width: currentWidth*0.86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white70, width: 1),
                      color: Colors.transparent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Form(
                            key: _formkey,
                            child: Expanded(
                              child: ListView(
                                children: [
                                  const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 5.0, top: 8.0),
                                        child: Text('Frequências a serem atenuadas:', style: TextStyle(color: Colors.white, fontSize: 20),),
                                      ),
                                  ),
                                  Container(
                                    height: 70,
                                    margin: EdgeInsets.only(left: 12, right: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        formTheme(currentWidth*0.7/5.1, dumper.freq[0].toString(), "Freq. 1 (Hz)", "Exemplo: 1863.0", 7.0, onWriting_form, validatorFreq, 'freq[0]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq[1].toString(), "Freq. 2 (Hz)", "Exemplo: 1470.0", 7.0, onWriting_form, validatorFreq, 'freq[1]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq[2].toString(), "Freq. 3 (Hz)", "Exemplo: 1034.0", 7.0, onWriting_form, validatorFreq, 'freq[2]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq[3].toString(), "Freq. 4 (Hz)", "Exemplo: 603.0", 7.0, onWriting_form, validatorFreq, 'freq[3]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq[4].toString(), "Freq. 5 (Hz)", "Exemplo: 360.0", 7.0, onWriting_form, validatorFreq, 'freq[4]'),
                                      ],
                                    ),
                                  ),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 5.0),
                                      child: Text('Importância de cada frequência:', style: TextStyle(color: Colors.white, fontSize: 20),),
                                    ),
                                  ),
                                  Container(
                                    height: 70,
                                    margin: EdgeInsets.only(left: 12, right: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        formTheme(currentWidth*0.7/5.1, dumper.freq_weight[0].toString(), "Peso 1", "Exemplo: 2.0", 7.0, onWriting_form, validatorFreq_weight, 'freq_weight[0]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq_weight[1].toString(), "Peso 2", "Exemplo: 3.0", 7.0, onWriting_form, validatorFreq_weight, 'freq_weight[1]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq_weight[2].toString(), "Peso 3", "Exemplo: 4.0", 7.0, onWriting_form, validatorFreq_weight, 'freq_weight[2]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq_weight[3].toString(), "Peso 4", "Exemplo: 5.0", 7.0, onWriting_form, validatorFreq_weight, 'freq_weight[3]'),
                                        formTheme(currentWidth*0.7/5.1, dumper.freq_weight[4].toString(), "Peso 5", "Exemplo: 1.0", 7.0, onWriting_form, validatorFreq_weight, 'freq_weight[4]'),
                                      ],
                                    ),
                                  ),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 10.0),
                                      child: Text('Informação gerais do atenuador:', style: TextStyle(color: Colors.white, fontSize: 20),),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 12, right: 12),
                                    height: 70,
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          formTheme(currentWidth*0.7/2, (dumper.width*1000).toString(), "Largura (mm)", "Exemplo: 50.0", 12.0, onWriting_form, validatorWidth, 'width'),
                                          formTheme(currentWidth*0.7/2, (dumper.lenght*1000).toString(), "Comprimento (mm)", "Exemplo: 490.0", 12.0, onWriting_form, validatorLenght, 'lenght'),
                                        ]
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0, right: 8.0, top:5),
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'Peso (Kg): ',
                                          style: TextStyle(color: Colors.white, fontSize: 15),
                                          children: <TextSpan>[
                                            TextSpan(text: '[${NumberFormat("#.0").format(double.parse((_rangeSlider_weight.start).toStringAsFixed(1)))}, ${NumberFormat("#.0").format(double.parse((_rangeSlider_weight.end).toStringAsFixed(1)))}]', style: TextStyle(color: Colors.white38, fontSize: 15),),
                                          ],
                                        ),
                                      )
                                    ),
                                  ),
                                  SfRangeSliderTheme(
                                    data: SfRangeSliderThemeData(
                                      tooltipBackgroundColor: Color(0xff62b5e5),
                                      activeTrackColor: Color(0xff62b5e5),
                                      activeLabelStyle: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                                      inactiveLabelStyle: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                                      activeTickColor: Colors.white,
                                      inactiveTickColor: Colors.white38,
                                    ),
                                    child:  SfRangeSlider(
                                      min: 1.0,
                                      max: 15.0,
                                      interval: currentWidth < 800 ? 2 : 1,
                                      showTicks: true,
                                      showLabels: true,
                                      showDividers: true,
                                      enableTooltip: true,
                                      numberFormat: NumberFormat("#.0 Kg"),
                                      values: _rangeSlider_weight,
                                      onChanged: (SfRangeValues newValues){
                                        setState(() {
                                          _rangeSlider_weight = newValues;
                                          dumper.min_weight = double.parse((newValues.start).toStringAsFixed(1));
                                          dumper.max_weight = double.parse((newValues.end).toStringAsFixed(1));
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 12.0),
                                            child: Text('Borracha/Mola:', style: TextStyle(color: Colors.white, fontSize: 20),),
                                          ),
                                          Container(
                                            width: currentWidth*0.65/2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                  padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                                                  child: RichText(
                                                    text: TextSpan(
                                                      text: 'Espessura da borracha aceita (mm): ',
                                                      style: TextStyle(color: Colors.white, fontSize: 15),
                                                      children: <TextSpan>[
                                                        TextSpan(text: '[${NumberFormat("#.0").format(double.parse((_rangeSlider_spring_thickness.start).toStringAsFixed(2)))}, ${NumberFormat("#.0").format(double.parse((_rangeSlider_spring_thickness.end).toStringAsFixed(2)))}]', style: TextStyle(color: Colors.white38, fontSize: 15),),
                                                      ],
                                                    ),
                                                  )
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: currentWidth*0.65/2,
                                            child: SfRangeSliderTheme(
                                              data: SfRangeSliderThemeData(
                                                tooltipBackgroundColor: Color(0xff62b5e5),
                                                activeTrackColor: Color(0xff62b5e5),
                                                activeLabelStyle: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                                                inactiveLabelStyle: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                                                activeTickColor: Colors.white,
                                                inactiveTickColor: Colors.white38,
                                              ),
                                              child:  SfRangeSlider(
                                                min: 0,
                                                max: 18.0,
                                                interval: (() {
                                                  if(currentWidth < 1050){
                                                    return 6.0;
                                                  }else if(currentWidth < 1450){
                                                    return 3.0;
                                                  }else{
                                                    return 2.0;
                                                  }
                                                }()),
                                                showTicks: true,
                                                showLabels: true,
                                                enableTooltip: true,
                                                numberFormat: NumberFormat("0.0 mm"),
                                                values: _rangeSlider_spring_thickness,
                                                onChanged: (SfRangeValues newValues){
                                                  setState(() {
                                                    _rangeSlider_spring_thickness = newValues;
                                                    dumper.min_springThickness_mm = double.parse((newValues.start).toStringAsFixed(1));
                                                    dumper.max_springThickness_mm = double.parse((newValues.end).toStringAsFixed(1));
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Column(
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(top: 30),
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Padding(
                                                          padding: const EdgeInsets.only(left: 12.0, right: 2.0),
                                                          child: RichText(
                                                            text: TextSpan(
                                                              text: 'Qtd. espessuras: ',
                                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                                              children: <TextSpan>[
                                                                TextSpan(text: NumberFormat("#").format(double.parse((qtd_springOp_aux).toString())), style: TextStyle(color: Colors.white60, fontSize: 12),),
                                                              ],
                                                            ),
                                                          )
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: currentWidth*0.65/3.5,
                                                    margin: EdgeInsets.only(bottom: 12, left: 0, right: 0),
                                                    child: SfSliderTheme(
                                                      data: SfSliderThemeData(
                                                        tooltipBackgroundColor: Color(0xff62b5e5),
                                                        activeTrackColor: Color(0xff62b5e5),
                                                        activeLabelStyle: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                                                        inactiveLabelStyle: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                                                        activeTickColor: Colors.white,
                                                        inactiveTickColor: Colors.white38,
                                                      ),
                                                      child:  SfSlider(
                                                        min: 1,
                                                        max: 10.0,
                                                        interval: 1,
                                                        showDividers: true,
                                                        showTicks: true,
                                                        showLabels: true,
                                                        enableTooltip: true,
                                                        numberFormat: NumberFormat("0"),
                                                        value: qtd_springOp,
                                                        onChanged: (dynamic newValue) {
                                                          setState(() {
                                                            qtd_springOp = newValue;
                                                            qtd_springOp_aux = newValue.round();
                                                            springOptionsThickness.visibility = false;
                                                            springOptionsThickness.height_max = 0;
                                                            Future.delayed(const Duration(milliseconds: 250), () { //asynchronous delay
                                                              setState(() { //tells the widget builder to rebuild again because ui has updated
                                                                if(qtd_springOp_aux < dumper.springOptions.length){
                                                                  dumper.springOptions.removeLast();
                                                                }else if(qtd_springOp_aux > dumper.springOptions.length){
                                                                  dumper.springOptions.add(2.0);
                                                                }
                                                              });
                                                            });
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              animationButton(springOptionsThickness, 133.0, 'spring'),
                                              SizedBox(width: 12,)
                                            ],
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(left: 12, right: 12),
                                            height: 70,
                                            child: formTheme(currentWidth*0.7/2.4, dumper.springDensity.toString(), "Densidade da borracha (Kg/m^3)", "Exemplo: 1300.0", 8.5, onWriting_form, validatorDensity, 'springDensity'),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(top: 5, left: 12, right: 12),
                                            height: 70,
                                            child: formTheme(currentWidth*0.7/2.4, (dumper.springElasticity/pow(10, 6)).toString(), "Elasticidade da borracha (MPa)", "Exemplo: 3.5", 8.5, onWriting_form, validatorElasticity, 'springElasticity'),
                                          ),
                                        ],
                                      ),
                                      //divisor
                                      Container(
                                        margin: EdgeInsets.only(top: 8, bottom: 8, left: 5, right: 5),
                                        width: 1,
                                        height: 370.0,
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(5.0),
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 12.0),
                                            child: Text('Aço/Massa:', style: TextStyle(color: Colors.white, fontSize: 20),),
                                          ),
                                          Container(
                                            width: currentWidth*0.65/2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Padding(
                                                  padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                                                  child: RichText(
                                                    text: TextSpan(
                                                      text: 'Espessura do aço aceita (mm): ',
                                                      style: TextStyle(color: Colors.white, fontSize: 15),
                                                      children: <TextSpan>[
                                                        TextSpan(text: '[${NumberFormat("#.0").format(double.parse((_rangeSlider_mass_thickness.start).toStringAsFixed(2)))}, ${NumberFormat("#.0").format(double.parse((_rangeSlider_mass_thickness.end).toStringAsFixed(2)))}]', style: TextStyle(color: Colors.white38, fontSize: 15),),
                                                      ],
                                                    ),
                                                  )
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: currentWidth*0.65/2,
                                            child: SfRangeSliderTheme(
                                              data: SfRangeSliderThemeData(
                                                tooltipBackgroundColor: Color(0xff62b5e5),
                                                activeTrackColor: Color(0xff62b5e5),
                                                activeLabelStyle: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                                                inactiveLabelStyle: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                                                activeTickColor: Colors.white,
                                                inactiveTickColor: Colors.white38,
                                              ),
                                              child:  SfRangeSlider(
                                                min: 0,
                                                max: 18.0,
                                                interval: (() {
                                                  if(currentWidth < 1050){
                                                    return 6.0;
                                                  }else if(currentWidth < 1450){
                                                    return 3.0;
                                                  }else{
                                                    return 2.0;
                                                  }
                                                }()),
                                                showTicks: true,
                                                showLabels: true,
                                                enableTooltip: true,
                                                numberFormat: NumberFormat("0.0 mm"),
                                                values: _rangeSlider_mass_thickness,
                                                onChanged: (SfRangeValues newValues){
                                                  setState(() {
                                                    _rangeSlider_mass_thickness = newValues;
                                                    dumper.min_massThickness_mm = double.parse((newValues.start).toStringAsFixed(1));
                                                    dumper.max_massThickness_mm = double.parse((newValues.end).toStringAsFixed(1));
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Column(
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.only(top: 30),
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Padding(
                                                          padding: const EdgeInsets.only(left: 12.0, right: 2.0),
                                                          child: RichText(
                                                            text: TextSpan(
                                                              text: 'Qtd. espessuras: ',
                                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                                              children: <TextSpan>[
                                                                TextSpan(text: NumberFormat("#").format(double.parse((qtd_massOp_aux).toString())), style: TextStyle(color: Colors.white60, fontSize: 12),),
                                                              ],
                                                            ),
                                                          )
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: currentWidth*0.65/3.5,
                                                    margin: EdgeInsets.only(bottom: 12, left: 0, right: 0),
                                                    child: SfSliderTheme(
                                                      data: SfSliderThemeData(
                                                        tooltipBackgroundColor: Color(0xff62b5e5),
                                                        activeTrackColor: Color(0xff62b5e5),
                                                        activeLabelStyle: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                                                        inactiveLabelStyle: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                                                        activeTickColor: Colors.white,
                                                        inactiveTickColor: Colors.white38,
                                                      ),
                                                      child:  SfSlider(
                                                        min: 1,
                                                        max: 10.0,
                                                        interval: 1,
                                                        showDividers: true,
                                                        showTicks: true,
                                                        showLabels: true,
                                                        enableTooltip: true,
                                                        numberFormat: NumberFormat("0"),
                                                        value: qtd_massOp,
                                                        onChanged: (dynamic newValue) {
                                                          setState(() {
                                                            qtd_massOp = newValue;
                                                            qtd_massOp_aux = newValue.round();
                                                            massOptionsThickness.visibility = false;
                                                            massOptionsThickness.height_max = 0;
                                                            Future.delayed(const Duration(milliseconds: 250), () { //asynchronous delay
                                                              setState(() { //tells the widget builder to rebuild again because ui has updated
                                                                if(qtd_massOp_aux < dumper.massOptions.length){
                                                                  dumper.massOptions.removeLast();
                                                                }else if(qtd_massOp_aux > dumper.massOptions.length){
                                                                  dumper.massOptions.add(2.0);
                                                                }
                                                              });
                                                            });
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              animationButton(massOptionsThickness, 133.0, 'mass'),
                                              SizedBox(width: 12,)
                                            ],
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(left: 12, right: 12),
                                            height: 70,
                                            child: formTheme(currentWidth*0.7/2.4, dumper.massDensity.toString(), "Densidade do aço (Kg/m^3)", "Exemplo: 7800.0", 8.5, onWriting_form, validatorDensity, 'massDensity'),
                                          ),
                                          const SizedBox(height: 75,)
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20,),
                                  Visibility(
                                    visible: advancedOptionsIsVisible,
                                    child: Column(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 12.0),
                                          child: Text('Configurações avançadas', style: TextStyle(color: Colors.white, fontSize: 20),),
                                        ),
                                        Container(
                                          height: 70,
                                          margin: EdgeInsets.only(left: 12, right: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              formTheme(currentWidth*0.7/3.0, (dumper.limit_generation).toString(), "Limite de gerações", "Exemplo: 200", 12, onWriting_form, validatorLimitGeneration, 'limitGeneration'),
                                              formTheme(currentWidth*0.7/3.0, (dumper.generation_size).toString(), "Tamanho da população", "Exemplo: 250", 12, onWriting_form, validatorGenerationSize, 'generationSize'),
                                              formTheme(currentWidth*0.7/3.0, (dumper.view_interval).toString(), "Tamanho da janela", "Exemplo: 50", 12, onWriting_form, validatorViewInterval, 'viewInterval'),
                                            ],
                                          ),
                                        ),
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 5.0),
                                            child: Text('Condição de parada: Erro em % por frequência:', style: TextStyle(color: Colors.white, fontSize: 20),),
                                          ),
                                        ),
                                        Container(
                                          height: 70,
                                          margin: EdgeInsets.only(left: 12, right: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              formTheme(currentWidth*0.7/5.1, dumper.freq_error[0].toString(), "Freq. 1 (%)", "Exemplo: 5.0", 7.0, onWriting_form, validatorFreq_error, 'freq_error[0]'),
                                              formTheme(currentWidth*0.7/5.1, dumper.freq_error[1].toString(), "Freq. 2 (%)", "Exemplo: 5.0", 7.0, onWriting_form, validatorFreq_error, 'freq_error[1]'),
                                              formTheme(currentWidth*0.7/5.1, dumper.freq_error[2].toString(), "Freq. 3 (%)", "Exemplo: 5.0", 7.0, onWriting_form, validatorFreq_error, 'freq_error[2]'),
                                              formTheme(currentWidth*0.7/5.1, dumper.freq_error[3].toString(), "Freq. 4 (%)", "Exemplo: 5.0", 7.0, onWriting_form, validatorFreq_error, 'freq_error[3]'),
                                              formTheme(currentWidth*0.7/5.1, dumper.freq_error[4].toString(), "Freq. 5 (%)", "Exemplo: 30.0", 7.0, onWriting_form, validatorFreq_error, 'freq_error[4]'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent,
                                          disabledForegroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                        ),
                                        onPressed: () {
                                          print("op. avançadas");
                                          if(_formkey.currentState!.validate()){
                                            setState(() {
                                              advancedOptionsIsVisible = !advancedOptionsIsVisible;
                                            });
                                          }

                                        },
                                        child: Text(
                                          advancedOptionsIsVisible ? 'Ver menos' : 'Configurações avançadas',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xff62b5e5),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15,)
                                ],
                              ),
                            ),
                          ),
                          //botão
                          Padding(
                            padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 0),
                            child: Container(
                              // margin: const EdgeInsets.only(left: 12, right: 12, bottom: 5),
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14.0),
                                gradient: const LinearGradient(
                                  begin: Alignment(-0.95, 0.0),
                                  end: Alignment(1.0, 0.0),
                                  colors: [Color(0xff2e2e52), Color(0xff62b5e5)],
                                  stops: [0.0, 1.0],
                                ),
                              ),
                              child: Container(
                                // width: 300,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent,
                                    disabledForegroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () {
                                    if(_formkey.currentState!.validate()){
                                      /*
                                      print("Botão enviar, formulário ok!");
                                      print("dumper: ");
                                      print("dumper.freq: ${dumper.freq}");
                                      print("dumper.freq_error: ${dumper.freq_error}");
                                      print("dumper.width: ${dumper.width}");
                                      print("dumper.lenght: ${dumper.lenght}");
                                      print("dumper.min_weight: ${dumper.min_weight}");
                                      print("dumper.max_weight: ${dumper.max_weight}");
                                      print("dumper.min_springThickness: ${dumper.min_springThickness}");
                                      print("dumper.max_springThickness: ${dumper.max_springThickness}");
                                      print("dumper.min_massThickness: ${dumper.min_massThickness}");
                                      print("dumper.max_massThickness: ${dumper.max_massThickness}");
                                      print("dumper.springOptions: ${dumper.springOptions}");
                                      print("dumper.massOptions: ${dumper.massOptions}");
                                      print("dumper.massDensity: ${dumper.massDensity}");
                                      print("dumper.springDensity: ${dumper.springDensity}");
                                      print("dumper.springElasticity: ${dumper.springElasticity}");
                                       */
                                      setState((){
                                        dumper.count = 0;
                                      });
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => HomePage(dumper: dumper)
                                          ));
                                    }
                                    // setState(){
                                    // }
                                  },
                                  child: const Center(
                                    child: Text(
                                      'Iniciar',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Color(0xffffffff),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
