// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors, prefer_const_constructors
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gluco/models/device.dart';
import 'package:gluco/services/bluetooth_helper.dart';
import 'package:gluco/styles/custom_colors.dart';
import 'package:gluco/styles/default_app_bar.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';

class DevicePage extends StatefulWidget {
  DevicePage();

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  final List<Device> devices = [];

  late Stream<bool> btState;
  late Stream<bool> btScan;
  late Stream<bool> btConn;

  void initScan() async {
    await BluetoothHelper.instance.scan();
  }

  void updateScanned() {
    devices.clear();
    devices.addAll(BluetoothHelper.instance.devices);
  }

  StreamController<bool> connecting = StreamController<bool>.broadcast();
  void connectDevice(bool cnt, int i) async {
    connecting.add(true);
    for (final dvc in devices) {
      dvc.connected = false;
    }
    await BluetoothHelper.instance.disconnect();
    if (cnt) {
      devices[i].connected = await BluetoothHelper.instance.connect(devices[i]);
    }
    connecting.add(false);
  }

  @override
  void initState() {
    btState = BluetoothHelper.instance.state;
    btScan = BluetoothHelper.instance.scanning;
    btConn = BluetoothHelper.instance.connected;
    btScan.listen(
      (value) {
        updateScanned();
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            CustomColors.bluelight,
            CustomColors.blueGreenlight,
            CustomColors.greenlight,
          ],
        ),
      ),
      child: Scaffold(
        appBar: defaultAppBar(
          title: context.loc.devicepage_prompt_watch_connection,
          trailing: [
            Padding(
              padding: EdgeInsets.all(15.0),
              child: Icon(Icons.bluetooth),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<bool>(
              stream: btScan,
              initialData: false,
              builder: (contextStreamScan, snapshot) {
                return Visibility(
                  // TODO: não é atualizado se desligar o bluetooth e a lista de devices
                  //  não estiver vazia, visto que atualiza pela stream de scan
                  visible: !snapshot.data! && devices.isNotEmpty,
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: 20.0, top: 5.0, bottom: 10.0),
                    child: Text(
                      context.loc.devicepage_prompt_available_devices,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 10.0),
                decoration: BoxDecoration(
                  color: CustomColors.scaffWhite.withOpacity(0.50),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: StreamBuilder<bool>(
                  stream: btState,
                  initialData: false,
                  builder: (contextStreamState, snapshot) {
                    if (!snapshot.data!) {
                      return Center(
                        child: Text(
                          context.loc.devicepage_error_bluetooth_off,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      );
                    } else {
                      initScan();
                      return StreamBuilder<bool>(
                        stream: btScan,
                        initialData: true,
                        builder: (contextStreamScan, snapshot) {
                          if (snapshot.data!) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: CustomColors.lightBlue,
                              ),
                            );
                          } else {
                            return devices.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        context.loc
                                            .devicepage_error_device_not_found,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                  )
                                : StreamBuilder<bool>(
                                    stream: btConn,
                                    initialData: true,
                                    builder: (contextStreamConn, snapshot) {
                                      return ListView.separated(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        itemCount: devices.length,
                                        itemBuilder: (contextItem, i) {
                                          return ListTile(
                                            title: Text(devices[i].name,
                                                style: TextStyle(
                                                    color:
                                                        devices[i].connected &&
                                                                snapshot.data!
                                                            ? CustomColors
                                                                .lightGreen
                                                            : Colors.black)),
                                            subtitle: Text(
                                                devices[i].connected &&
                                                        snapshot.data!
                                                    ? context.loc.connected
                                                    : context.loc.not_connected,
                                                style: TextStyle(
                                                    color:
                                                        devices[i].connected &&
                                                                snapshot.data!
                                                            ? CustomColors
                                                                .lightGreen
                                                            : Colors.black)),
                                            trailing: IconButton(
                                              icon: Icon(Icons.settings,
                                                  color: devices[i].connected &&
                                                          snapshot.data!
                                                      ? CustomColors.lightGreen
                                                      : Colors.black),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (contextDialog) {
                                                    return AlertDialog(
                                                      title: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          // TODO: verificar por que permanece verde mesmo após desconectar por sinal perdido
                                                          StreamBuilder<bool>(
                                                            stream: btConn,
                                                            initialData: true,
                                                            builder:
                                                                (contextStreamConn,
                                                                    snapshot) {
                                                              return RichText(
                                                                text: TextSpan(
                                                                  text:
                                                                      devices[i]
                                                                          .name,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      color: devices[i].connected &&
                                                                              snapshot
                                                                                  .data!
                                                                          ? CustomColors
                                                                              .lightGreen
                                                                          : Colors
                                                                              .black),
                                                                  children: [
                                                                    TextSpan(
                                                                      text: devices[i].connected &&
                                                                              snapshot.data!
                                                                          ? '\n${context.loc.connected}'
                                                                          : '\n${context.loc.not_connected}',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontStyle:
                                                                            FontStyle.italic,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),

                                                          StreamBuilder<bool>(
                                                            stream: connecting
                                                                .stream,
                                                            initialData: false,
                                                            builder:
                                                                (contextStreamConn,
                                                                    snapshot) {
                                                              if (snapshot
                                                                  .data!) {
                                                                return CircularProgressIndicator(
                                                                  color: CustomColors
                                                                      .lightBlue,
                                                                );
                                                              } else {
                                                                return Switch(
                                                                  activeColor:
                                                                      CustomColors
                                                                          .lightGreen,
                                                                  value: devices[
                                                                          i]
                                                                      .connected,
                                                                  onChanged:
                                                                      (value) {
                                                                    connectDevice(
                                                                        value,
                                                                        i);
                                                                  },
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      actionsAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      actions: [
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons.arrow_back),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                contextDialog);
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        separatorBuilder: (contextSep, i) {
                                          return Divider(
                                            color: Colors.grey,
                                          );
                                        },
                                      );
                                    },
                                  );
                          }
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: btState,
          initialData: false,
          builder: (contextStreamState, snapshot) {
            return Visibility(
              visible: snapshot.data!,
              child: StreamBuilder<bool>(
                stream: btScan,
                initialData: false,
                builder: (contextStreamScan, snapshot) {
                  VoidCallback? onPressed;
                  Color color = Colors.grey;
                  if (!snapshot.data!) {
                    color = CustomColors.lightBlue;
                    onPressed = initScan;
                  }
                  return FloatingActionButton(
                    backgroundColor: color,
                    onPressed: onPressed,
                    shape: OvalBorder(),
                    child: Icon(Icons.refresh, color: Colors.white),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
