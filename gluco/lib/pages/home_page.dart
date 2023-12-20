// ignore_for_file: use_key_in_widget_constructors, must_be_immutable, prefer_const_constructors, empty_catches

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:gluco/db/database_helper.dart';
import 'package:gluco/models/measurement.dart';
import 'package:gluco/models/exceptions/home_exceptions.dart';
import 'package:gluco/models/patient.dart';
import 'package:gluco/services/api.dart';
import 'package:gluco/services/bluetooth_helper.dart';
import 'package:gluco/styles/default_app_bar.dart';
import 'package:gluco/styles/main_bottom_app_bar.dart';
import 'package:gluco/styles/custom_colors.dart';
import 'package:gluco/views/history_view.dart';
import 'package:gluco/widgets/icon_card.dart';
import 'package:gluco/widgets/patient_dropdown.dart';
import 'package:gluco/widgets/side_bar.dart';
import 'package:intl/intl.dart';
import 'package:gluco/app_icons.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';

class HomePage extends StatefulWidget {
  bool offline;
  bool popup = true;
  HomePage({this.offline = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<bool> btConn;

  late TextEditingController controllerPatient;
  final List<Patient> patientsList = [];

  @override
  void initState() {
    btConn = BluetoothHelper.instance.connected;
    controllerPatient = TextEditingController();
    WidgetsBinding.instance
        .addPostFrameCallback(_dialogNoConnection(context, widget));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (patientsList.isEmpty) {
      patientsList.add(Patient(clientId: '', serviceNumber: context.loc.me));
      patientsList.addAll(API.instance.patientList);
    }
    Size heightSize = Size.fromHeight(MediaQuery.of(context).size.height *
        (MediaQuery.of(context).orientation == Orientation.portrait
            ? 0.2
            : 0.4));
    ValueListenableBuilder<bool> glucoseCard = ValueListenableBuilder<bool>(
      valueListenable: HistoryView.updatedView,
      builder: (_, value, __) {
        return IconCard(
          icon: Icon(AppIcons.molecula, color: Colors.white, size: 32),
          label: Text(
            context.loc.glucose,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          data: HistoryView.currentMeasurement.id != -1
              ? Text(
                  '${HistoryView.currentMeasurement.glucose} mg/dL',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(context.loc.no_data),
          color: CustomColors.lightBlue.withOpacity(1.0),
          size: heightSize,
        );
      },
    );
    ValueListenableBuilder<bool> spo2Card = ValueListenableBuilder<bool>(
      valueListenable: HistoryView.updatedView,
      builder: (_, value, __) {
        return IconCard(
          icon: Icon(Icons.air, color: Colors.white),
          label: Text(
            context.loc.oxygen_saturation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          data: HistoryView.currentMeasurement.id != -1
              ? Text(
                  '${HistoryView.currentMeasurement.spo2}%',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(context.loc.no_data),
          color: CustomColors.lightGreen.withOpacity(1.0),
          size: heightSize,
        );
      },
    );
    ValueListenableBuilder<bool> rpmCard = ValueListenableBuilder<bool>(
      valueListenable: HistoryView.updatedView,
      builder: (_, value, __) {
        return IconCard(
          icon: Icon(Icons.favorite, color: Colors.white),
          label: Text(
            context.loc.heart_rate,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          data: HistoryView.currentMeasurement.id != -1
              ? Text(
                  '${HistoryView.currentMeasurement.pr_rpm} bpm',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(context.loc.no_data),
          color: CustomColors.greenBlue.withOpacity(1.0),
          size: heightSize,
        );
      },
    );
    return Scaffold(
      backgroundColor: CustomColors.scaffLightBlue,
      appBar: imageAppBar(
        // TODO: Trocar literal para generate
        imagename: 'assets/images/logoblue.png',
        width: MediaQuery.of(context).size.width * 0.25,
      ),
      bottomNavigationBar: MainBottomAppBar(page: MainBottomAppBarEnum.home),
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
                  ValueListenableBuilder<bool>(
                    valueListenable: HistoryView.updatedView,
                    builder: (_, value, __) {
                      return RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text:
                              '${context.loc.homepage_view_last_measurement}: ${MediaQuery.of(context).orientation == Orientation.portrait ? '\n' : ' '}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16.0,
                          ),
                          children: [
                            TextSpan(
                              text: HistoryView.currentMeasurement.id != -1
                                  ? DateFormat('d MMM, E H:mm', 'pt_BR')
                                      .format(
                                          HistoryView.currentMeasurement.date)
                                      .toUpperCase()
                                  : context.loc.no_data,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            MediaQuery.of(context).orientation == Orientation.portrait
                ? Column(
                    children: [
                      glucoseCard,
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.025),
                      Row(
                        children: [
                          Expanded(
                            child: spo2Card,
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.025),
                          Expanded(
                            child: rpmCard,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: glucoseCard),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015),
                      Expanded(child: spo2Card),
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.015),
                      Expanded(child: rpmCard)
                    ],
                  ),
            if (API.instance.isDoctor)
              PatientDropdown(
                controller: controllerPatient,
                entries: patientsList,
                shadow: true,
                onSelected: (pat) async {
                  // TODO: provalmente ficar fazendo requisição assim vai dar errado
                  // await HistoryView.fetchHistory(pat?.clientId);
                },
              ),
            StreamBuilder<bool>(
              stream: btConn,
              initialData: false,
              builder: (contextStream, snapshot) {
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
                      // TODO: tirar context de async gap
                      await _dialogErrorBluetooth(context);
                      throw MeasurementCollectionHomeException();
                    }
                    bool response = false;
                    // TODO: tirar context de async gap
                    response = await _dialogMeasurement(
                      context,
                      measurement,
                      controllerPatient,
                      patientsList,
                    );
                    if (!response) {
                      throw MeasurementCancelledHomeException();
                    }
                    // /////////// TODO: talvez isso esteja errado, consistencia
                    // HistoryView.currentMeasurement.id++;
                    // HistoryView.currentMeasurement.spo2 = measurement.spo2;
                    // HistoryView.currentMeasurement.pr_rpm = measurement.pr_rpm;
                    // HistoryView.currentMeasurement.glucose =
                    //     measurement.apparent_glucose ?? -1;
                    // HistoryView.currentMeasurement.date = measurement.date;
                    // HistoryView.updateMeasurementsMap();
                    // ///////////
                    // await DatabaseHelper.instance.insertMeasurementCompleted(
                    //     API.instance.currentUser!,
                    //     HistoryView.currentMeasurement);
                    // ///////////
                  },
                  builder: (contextButton, child, callback, _) {
                    Color color = CustomColors.greenBlue.withOpacity(1.0);
                    if (!snapshot.data!) {
                      color = Colors.grey;
                      callback = _dialogNoDevice(context);
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
                    context.loc.measure,
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

void Function(Duration) _dialogNoConnection(
  BuildContext context,
  HomePage widget,
) {
  return (_) async {
    if (widget.offline && widget.popup) {
      await showDialog(
        context: context,
        builder: (contextNoConn) {
          return AlertDialog(
            title: Text(context.loc.generic_error_no_connection),
            content: Text(context.loc.homepage_view_no_connection),
            elevation: 4.0,
            backgroundColor: CustomColors.scaffLightBlue,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(contextNoConn).pop();
                },
                child: Text(context.loc.ok),
              )
            ],
          );
        },
      );
      widget.popup = false;
    }
  };
}

Future<void> _dialogErrorBluetooth(BuildContext context) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (contextErrorBlue) {
      return AlertDialog(
        title: Text(context.loc.homepage_error_bluetooth),
        content: SingleChildScrollView(
          child: Column(
            children: [Text('${BluetoothHelper.instance.valuesError}')],
          ),
        ),
        elevation: 4.0,
        backgroundColor: CustomColors.scaffLightBlue,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        actions: [
          TextButton(
            onPressed: (() {
              Navigator.pop(contextErrorBlue);
            }),
            child: Text(context.loc.return_p),
          )
        ],
      );
    },
  );
}

Future<bool> _dialogMeasurement(
  BuildContext context,
  MeasurementCollected measurement,
  TextEditingController controllerPatient,
  List<Patient> patientsList,
) async {
  final formKey = GlobalKey<FormState>();
  bool isSuccess = false;
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (contextMeasurement) {
      TextEditingController controllerDiabetes = TextEditingController();
      return AlertDialog(
        title: Text(context.loc.homepage_prompt_send_measurement),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4.0,
        backgroundColor: CustomColors.scaffLightBlue,
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.always,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (API.instance.isDoctor)
                PatientDropdown(
                  controller: controllerPatient,
                  entries: patientsList,
                ).build(context),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
              ),
              TextFormField(
                controller: controllerDiabetes,
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: const TextStyle(color: Colors.black),
                  labelText: context.loc.homepage_prompt_glucose_measurement,
                  filled: true,
                  fillColor: Colors.white,
                  border: UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  String? message;
                  try {
                    double.parse(value!);
                  } catch (e) {
                    message = context.loc.homepage_prompt_decimal_value;
                  }
                  return message;
                },
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _dialogConfirmCancel(context, contextMeasurement);
            },
            child: Text(
              context.loc.cancel,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              backgroundColor: CustomColors.lightGreen,
            ),
            child: Text(
              context.loc.send,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) {
                throw MeasurementFormHomeException();
              }
              measurement.apparent_glucose =
                  double.parse(controllerDiabetes.text);

              //TODO: a seleção do paciente tá sendo feita de uma maneira burra mas ok
              Patient? patient;
              try {
                patient = API.instance.patientList.firstWhere(
                  (e) => e.serviceNumber == controllerPatient.text,
                );
              } catch (_) {}

              isSuccess = await _dialogConfirmMeasurement(
                context,
                contextMeasurement,
                measurement,
                patient,
              );

              if (isSuccess) {
                // TODO: tirar context de async gap
                Navigator.pop(contextMeasurement);
              }
            },
          )
        ],
      );
    },
  );
  return isSuccess;
}

Future<void> _dialogConfirmCancel(
  BuildContext context,
  BuildContext contextMeasurement,
) async {
  await showDialog(
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    context: contextMeasurement,
    builder: (contextCancel) {
      return AlertDialog(
        title: Text(context.loc.generic_dialog_cancel),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4.0,
        backgroundColor: CustomColors.scaffLightBlue,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              backgroundColor: Colors.red.shade900,
            ),
            onPressed: () {
              Navigator.pop(contextCancel);
              Navigator.pop(contextMeasurement);
            },
            child: Text(
              context.loc.cancel,
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
              backgroundColor: CustomColors.lightGreen,
            ),
            onPressed: () {
              Navigator.pop(contextCancel);
            },
            child: Text(
              context.loc.homepage_prompt_continue_measurement,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          )
        ],
      );
    },
  );
}

Future<bool> _dialogConfirmMeasurement(
  BuildContext context,
  BuildContext contextMeasurement,
  MeasurementCollected measurement,
  Patient? patient,
) async {
  bool isSuccess = false;
  await showDialog(
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    context: contextMeasurement,
    builder: (contextConfirm) {
      return AlertDialog(
        title: Text(context.loc.homepage_prompt_confirm_data),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (API.instance.isDoctor)
              // TODO: é uma solução tapa buraco esse null coisa
              Text(
                  '${context.loc.patient}: ${patient?.serviceNumber ?? context.loc.me}'),
            Text('${context.loc.glucose}: ${measurement.apparent_glucose}'),
          ],
        ),
        elevation: 4.0,
        backgroundColor: CustomColors.scaffLightBlue,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(contextConfirm);
            },
            child: Text(
              context.loc.correct,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          AsyncButtonBuilder(
            onPressed: () async {
              isSuccess = await API.instance
                  .postMeasurements(measurement, patient?.clientId);
              // TODO: tirar context de async gap
              await _dialogSentMeasurement(context, contextMeasurement,
                  contextConfirm, measurement, isSuccess);
              if (!isSuccess) {
                if (!API.instance.isDoctor) {
                  await DatabaseHelper.instance.insertMeasurementCollected(
                      API.instance.currentUser!, measurement);
                }
                // TODO: tirar context de async gap
                Navigator.pop(contextConfirm);
                Navigator.pop(contextMeasurement);
              } else {
                // TODO: tirar context de async gap
                Navigator.pop(contextConfirm);
              }
            },
            builder: (cont, child, callback, _) {
              return TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  backgroundColor: CustomColors.lightGreen,
                ),
                onPressed: callback,
                child: child,
              );
            },
            child: Text(
              context.loc.confirm,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          )
        ],
      );
    },
  );
  return isSuccess;
}

Future<void> _dialogSentMeasurement(
  BuildContext context,
  BuildContext contextMeasurement,
  BuildContext contextConfirm,
  MeasurementCollected measurement,
  bool isSuccess,
) async {
  await showDialog(
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    context: contextConfirm,
    builder: (contextSent) {
      return AlertDialog(
        title: Text(
          isSuccess
              ? context.loc.homepage_prompt_measurement_sent
              : context.loc.homepage_error_measurement_not_sent,
          style: TextStyle(color: isSuccess ? null : Colors.red.shade900),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: measurement
                .toMap()
                .entries
                .map((e) => Text('${e.key}: ${e.value}'))
                .toList(),
          ),
        ),
        elevation: 4.0,
        backgroundColor: CustomColors.scaffLightBlue,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        actions: [
          TextButton(
            onPressed: (() {
              Navigator.pop(contextSent);
            }),
            child: Text(isSuccess ? context.loc.ok : context.loc.return_p),
          )
        ],
      );
    },
  );
}

Future<void> Function()? _dialogNoDevice(BuildContext context) {
  return () async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (contextNoDev) {
        return AlertDialog(
          title: Text(context.loc.homepage_error_device_not_connected),
          content: Text(context.loc.homepage_prompt_connect_device),
          elevation: 4.0,
          backgroundColor: CustomColors.scaffLightBlue,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                backgroundColor: CustomColors.lightGreen,
              ),
              onPressed: () async {
                await Navigator.popAndPushNamed(context, '/devices');
              },
              child: Text(
                context.loc.homepage_prompt_go_to_devicepage,
                style: TextStyle(color: CustomColors.white),
              ),
            )
          ],
        );
      },
    );
  };
}
