// ignore_for_file: use_key_in_widget_constructors, must_be_immutable, prefer_const_constructors, use_build_context_synchronously, empty_catches

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:gluco/db/databasehelper.dart';
import 'package:gluco/models/measurement.dart';
import 'package:gluco/services/api.dart';
import 'package:gluco/services/bluetoothhelper.dart';
import 'package:gluco/styles/defaultappbar.dart';
import 'package:gluco/styles/mainbottomappbar.dart';
import 'package:gluco/styles/customcolors.dart';
import 'package:gluco/views/historyvo.dart';
import 'package:gluco/widgets/iconcard.dart';
import 'package:gluco/widgets/sidebar.dart';
import 'package:intl/intl.dart';
import 'package:gluco/app_icons.dart';

class HomePage extends StatefulWidget {
  bool offline;
  bool popup = true;
  HomePage({this.offline = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<bool> btConn;

  @override
  void initState() {
    btConn = BluetoothHelper.instance.connected;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (widget.offline && widget.popup) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Sem conexão'),
                content: Text('Sem Internet os recursos serão limitados'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  )
                ],
              );
            },
          );
          widget.popup = false;
        }
      },
    );
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.scaffLightBlue,
      appBar: imageAppBar(
        imagename: 'assets/images/logoblue.png',
        width: MediaQuery.of(context).size.width * 0.25,
      ),
      bottomNavigationBar: mainBottomAppBar(context, MainBottomAppBar.home),
      drawer: SideBar(),
      body: Container(
        margin: EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment:
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.spaceBetween,
          children: [
            Container(
              alignment: Alignment.center,
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text:
                          'Última medição: ${MediaQuery.of(context).orientation == Orientation.portrait ? '\n' : ' '}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16.0,
                      ),
                      children: [
                        TextSpan(
                          text: HistoryVO.currentMeasurement.id != -1
                              ? DateFormat('d MMM, E. H:mm', 'pt_BR')
                                  .format(HistoryVO.currentMeasurement.date)
                                  .toUpperCase()
                              : 'Sem dados',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconCard(
                  icon: Icon(AppIcons.molecula, color: Colors.white, size: 32),
                  label: Text(
                    'Glicose',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  data: HistoryVO.currentMeasurement.id != -1
                      ? Text(
                          '${HistoryVO.currentMeasurement.glucose} mg/dL',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text('Sem dados'),
                  color: CustomColors.lightBlue.withOpacity(1.0),
                  size:
                      Size.fromHeight(MediaQuery.of(context).size.height * 0.2),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                Row(
                  children: [
                    Expanded(
                      child: IconCard(
                        icon: Icon(Icons.air, color: Colors.white),
                        label: Text(
                          'Saturação de Oxigênio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        data: HistoryVO.currentMeasurement.id != -1
                            ? Text(
                                '${HistoryVO.currentMeasurement.spo2}%',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text('Sem dados'),
                        color: CustomColors.lightGreen.withOpacity(1.0),
                        size: Size.fromHeight(
                            MediaQuery.of(context).size.height * 0.2),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.025),
                    Expanded(
                      child: IconCard(
                        icon: Icon(Icons.favorite, color: Colors.white),
                        label: Text(
                          'Frequência Cardíaca',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        data: HistoryVO.currentMeasurement.id != -1
                            ? Text(
                                '${HistoryVO.currentMeasurement.pr_rpm} bpm',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text('Sem dados'),
                        color: CustomColors.greenBlue.withOpacity(1.0),
                        size: Size.fromHeight(
                            MediaQuery.of(context).size.height * 0.2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StreamBuilder<bool>(
              // stream: btConn,
              stream: Stream.value(true), // teste para o botao habilitar
              initialData: false,
              builder: (context, snapshot) {
                return AsyncButtonBuilder(
                  loadingWidget: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3.0,
                  ),
                  successWidget: Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    late MeasurementCollected measurement;
                    try {
                      measurement = await BluetoothHelper.instance.collect();
                    } catch (e) {
                      await showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                                title: Text(
                                    'Ocorreu um erro na coleta dos dados do dispositivo Bluetooth...'),
                                actions: [
                                  TextButton(
                                    onPressed: (() {
                                      Navigator.pop(context);
                                    }),
                                    child: Text('Retornar'),
                                  )
                                ]);
                          });
                      throw 'Erro na coleta da medição'; // pro async_button mostrar ícone certo
                    }
                    bool response = false;
                    await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (contextSD1) {
                          TextEditingController controller =
                              TextEditingController();
                          return AlertDialog(
                              title: Text('Insira o valor da glicose:'),
                              content: Form(
                                key: _formKey,
                                autovalidateMode: AutovalidateMode.always,
                                child: TextFormField(
                                  controller: controller,
                                  validator: (value) {
                                    String? message;
                                    try {
                                      double.parse(value!);
                                    } catch (e) {
                                      message =
                                          'Insira um valor de ponto flutuante.';
                                    }
                                    return message;
                                  },
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: contextSD1,
                                        builder: (contextSD2r) {
                                          return AlertDialog(
                                            title: Text(
                                                'Certeza que deseja cancelar?'),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  'Sim, cancelar',
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(contextSD2r);
                                                  Navigator.pop(contextSD1);
                                                },
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        CustomColors
                                                            .lightGreen),
                                                onPressed: () {
                                                  Navigator.pop(contextSD2r);
                                                },
                                                child: Text(
                                                  'Não, continuar medição',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                            ],
                                          );
                                        });
                                  },
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                      backgroundColor: CustomColors.lightGreen),
                                  child: Text(
                                    'Enviar',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (!(_formKey.currentState?.validate() ??
                                        false)) {
                                      throw 'Form inválido';
                                    }
                                    measurement.apparent_glucose =
                                        double.parse(controller.text);
                                    showDialog(
                                      barrierDismissible: false,
                                      context: contextSD1,
                                      builder: (contextSD2) {
                                        return AlertDialog(
                                            title: Text('Confira os dados!'),
                                            content: Text(
                                                'Glicose: ${measurement.apparent_glucose}'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(contextSD2);
                                                },
                                                child: Text(
                                                  'Corrigir',
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                ),
                                              ),
                                              AsyncButtonBuilder(
                                                onPressed: () async {
                                                  response = await API.instance
                                                      .postMeasurements(
                                                          measurement);
                                                  if (!response) {
                                                    DatabaseHelper.instance
                                                        .insertMeasurementCollected(
                                                            API.instance
                                                                .currentUser!,
                                                            measurement);
                                                  }
                                                  showDialog(
                                                      barrierDismissible: false,
                                                      context: contextSD2,
                                                      builder: (contextSD3) {
                                                        return AlertDialog(
                                                            title: Text(response
                                                                ? 'Medição enviada com sucesso'
                                                                : 'Ocorreu um erro no envio dos dados coletados, eles serão armazenados até que seja possível enviar...'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: (() {
                                                                  Navigator.pop(
                                                                      contextSD3);
                                                                  Navigator.pop(
                                                                      contextSD2);
                                                                  Navigator.pop(
                                                                      contextSD1);
                                                                }),
                                                                child: Text(response
                                                                    ? 'Ok!'
                                                                    : 'Retornar'),
                                                              )
                                                            ]);
                                                      });
                                                },
                                                builder:
                                                    (cont, child, callback, _) {
                                                  return TextButton(
                                                    style: TextButton.styleFrom(
                                                        backgroundColor:
                                                            CustomColors
                                                                .lightGreen),
                                                    onPressed: callback,
                                                    child: child,
                                                  );
                                                },
                                                child: Text(
                                                  'Confirmar',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                            ]);
                                      },
                                    );
                                  },
                                )
                              ]);
                        });
                    if (!response) {
                      throw 'Envio da medição cancelada'; // pro async_button mostrar ícone certo
                    }
                    /////////////////// futuro
                    // MeasurementCompleted measurement = await API.instance.getMeasurement();
                    // DatabaseHelper.instance
                    //     .insertMeasurement(API.instance.currentUser!, measurement);
                    ///////////////////
                  },
                  builder: (context, child, callback, _) {
                    Color color = CustomColors.greenBlue.withOpacity(1.0);
                    if (!snapshot.data!) {
                      color = Colors.grey;
                      callback = () async {
                        await showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Dispositivo não conectado'),
                              content: Text(
                                  'Escolha um dispositivo para conectar na página de dispositivos...'),
                              actions: [
                                TextButton(
                                  child: Text('Ir à página de dispositivos'),
                                  onPressed: () async {
                                    await Navigator.popAndPushNamed(
                                      context,
                                      '/devices',
                                    );
                                  },
                                )
                              ],
                            );
                          },
                        );
                      };
                    }
                    return TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: Size.fromHeight(
                            MediaQuery.of(context).size.height * 0.09),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: callback,
                      child: child,
                    );
                  },
                  child: Text(
                    'Medir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
