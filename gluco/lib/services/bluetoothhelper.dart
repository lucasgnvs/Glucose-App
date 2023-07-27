import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gluco/models/device.dart';
import 'package:gluco/models/measurement.dart';
import 'package:gluco/services/customlog.dart';

class BluetoothHelper {
  BluetoothHelper._privateConstructor();

  static final BluetoothHelper instance = BluetoothHelper._privateConstructor();

  // Dispositivo atualmente conectado, é o que é efetivamente utilizado na coleta
  _DeviceInternal? _connectedDevice;

  // Lista de dados recebidos em coleta com erro
  List<String> valuesError = [];

  /// Stream com sinais de alteração no estado do Bluetooth ligado/desligado
  Stream<bool> get state => _state().asBroadcastStream();

  /// Stream que encapsula e transmite os sinais de estado do FlutterBlue
  Stream<bool> _state() async* {
    await for (final value in FlutterBluePlus.adapterState) {
      bool available = value == BluetoothAdapterState.on ? true : false;
      if (!available) {
        disconnect();
        _devices.clear();
      }
      yield available;
    }
  }

  /// Stream com sinais de iniciando/parando escaneamento
  Stream<bool> get scanning => _scanning().asBroadcastStream();

  /// Stream que encapsula e transmite os sinais de escaneamento do FlutterBlue
  Stream<bool> _scanning() async* {
    await for (final value in FlutterBluePlus.isScanning) {
      yield value;
    }
  }

  /// Stream com sinais de conectado/desconectado do dispositivo atualmente conectado
  Stream<bool> get connected => _connected.stream;
  final StreamController<bool> _connected = StreamController<bool>.broadcast();

  /// Inicia a alimentação da stream do estado de conexão do dispositivo
  /// continuamente até que seja desconectado, tenta reconectar automaticamente
  /// se a desconexão não foi solicitada de forma manual
  void _yieldConnection() async {
    // envia o primeiro valor, pq o da stream state é perdido
    _connected.add(true);
    String error = 'Connected';
    try {
      await for (final value in _connectedDevice!.device.connectionState) {
        bool conn = value == BluetoothConnectionState.connected ? true : false;
        // tenta reconectar
        if (!conn) {
          if (await connect(
              Device(id: _connectedDevice!.device.remoteId.str))) {
            conn = true;
            error = 'Reconnected';
          } else {
            disconnect();
            error = 'Disconnected by signal loss';
          }
        }
        _connected.add(conn);
        log.i('YieldConnection :: $conn : $error');
        error = 'Connected';
      }
    } catch (e) {
      // sempre termina por exceção pois na desconexão
      // _connectedDevice é setado com nulo e é usado null check no for
      _connected.add(false);
      // error = 'Exception: $e';
    }
    log.w('--- YieldConnection :: Terminated : $error');
  }

  /// Lista de dispositivos encontrados pelo escaneamento
  final List<BluetoothDevice> _devices = [];

  /// Mapeamento dos BluetoothDevices para Devices com inclusão do
  /// dispositivo atualmente conectado
  List<Device> get devices {
    List<Device> dvcs = _devices
        .map((d) => Device(id: d.remoteId.str, name: d.localName))
        .toList();
    if (_connectedDevice != null) {
      // encontra o dispositivo conectado e marca como conectado
      dvcs
          .firstWhere((d) => d.id == _connectedDevice!.device.remoteId.str)
          .connected = true;
    }
    return dvcs;
  }

  /// Inicia escaneamento e inclui os resultados em devices
  Future<void> scan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
    FlutterBluePlus.scanResults.listen(
      (results) {
        _devices.clear();
        for (ScanResult r in results) {
          if (RegExp(r'MXCHIP.*', dotAll: true).hasMatch(r.device.localName)) {
            // if (RegExp(r'.*', dotAll: true).hasMatch(r.device.name)) {
            _devices.add(r.device);
            log.i(
                "--- Scan device :: ${r.device.localName} - ${r.device.remoteId.str}");
          }
        }
      },
    );
    await FlutterBluePlus.stopScan();
    if (_connectedDevice != null) {
      // dispositivos conectados não são inseridos automaticamente
      // na lista de scan do FlutterBlue
      _devices.insert(0, _connectedDevice!.device);
    }
  }

  /// Tenta estabelecer conexão com um dispositivo, pode falhar por timeout,
  /// se bem sucedido _connectedDevice é atualizado e a transmissão
  /// da stream de conexão é iniciada
  Future<bool> connect(Device dvc) async {
    bool status = true;
    String error = 'Success';
    try {
      BluetoothDevice device =
          _devices.firstWhere((d) => d.remoteId.str == dvc.id);
      // autoConnect como true tava dando problema no _connectedDevice ser setado com null
      await device
          .connect(autoConnect: false)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        status = false;
        device.disconnect();
        error = 'Timeout';
      }).whenComplete(() async {
        if (status) {
          // Busca pelos descritores das características por correspondência com RX e TX
          BluetoothCharacteristic? rx;
          BluetoothCharacteristic? tx;
          List<BluetoothService> services = await device.discoverServices();
          try {
            List<BluetoothCharacteristic> characteristics =
                services.firstWhere((element) {
              String id = element.uuid.toString().toUpperCase().substring(4, 8);
              return id == 'E0FF' || id == '8251';
            }).characteristics;
            rx = characteristics.firstWhere((element) {
              String id = element.uuid.toString().toUpperCase().substring(4, 8);
              return id == 'FFE2' || id == '2D3F';
            });
            tx = characteristics.firstWhere((element) {
              String id = element.uuid.toString().toUpperCase().substring(4, 8);
              return id == 'FFE1' || id == 'F2A8';
            });
          } catch (e) {
            log.w('--- Connect :: Characteristics not found');
          }
          /*
          for (BluetoothService s in services) {
            for (BluetoothCharacteristic c in s.characteristics) {
              for (BluetoothDescriptor d in c.descriptors) {
                List<int> hex = await d.read();
                String value = utf8.decode(hex, allowMalformed: true);
                if (value == 'RXD Port') {
                  rx = c;
                }
                if (value == 'TXD Port') {
                  tx = c;
                }
              }
            }
          }
          */
          // estabelece novo dispositivo conectado, inicia a stream de conexão,
          // e inicia transmissão do sinal que solicita medição
          if (rx != null && tx != null) {
            _connectedDevice =
                _DeviceInternal(device: device, receiver: rx, transmitter: tx);
            await _saveDevice(device.remoteId.str);
            // ### falta: função para verificar se possui medições nao recebidas
            _yieldConnection();
          } else {
            device.disconnect();
            status = false;
            error = 'RX or TX not found';
          }
        }
      });
    } catch (e) {
      status = false;
      error = 'Exception: $e';
    }
    log.i('--- Connection status :: $status : $error');
    return status;
  }

  /// Encapsula a função de desconectar do FlutterBlue, é a única que seta
  /// _connectedDevice como null
  Future<bool> disconnect() async {
    try {
      BluetoothDevice dvc = _connectedDevice!.device;
      _connectedDevice = null;
      await dvc.disconnect();
      log.i('--- Disconnected');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Busca por um dispositivo previamente conectado no SharedPreferences
  /// para tentar reconectar ao iniciar o aplicativo
  // ### Como fazer para reconectar
  // ### mesmo após já estar com app aberto e ter perdido conexão ????
  Future<bool> autoConnect() async {
    String? deviceId = await _fetchDevice();
    if (deviceId == null) {
      return false;
    }
    log.i('--- AutoConnect SP :: $deviceId');
    await scan();
    return await connect(Device(id: deviceId));
  }

  /// Salva o id do dispositivo conectado no SharedPreferences
  Future<bool> _saveDevice(String id) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return await sp.setString('egble', id);
  }

  /// Recupera o id do último dispositivo conectado do SharedPreferences
  Future<String?> _fetchDevice() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('egble');
  }

  /// Faz a leitura dos dados da medição do dispositivo conectado VERSÃO RANDOM
  @Deprecated('Utilizado apenas como teste')
  Future<MeasurementCollected> collect_rand() async {
    Random random = Random();
    List<double> maxled = <double>[];
    List<double> minled = <double>[];
    List<double> m_4p = <double>[];
    List<double> f_4p = <double>[];
    List<double> m_2p = <double>[];
    List<double> f_2p = <double>[];
    for (int i = 1; i <= 4; i++) {
      maxled.add((random.nextDouble() * 10000).truncateToDouble() / 1000 + 7);
      minled.add((random.nextDouble() * 10000).truncateToDouble() / 1000 + 3);
    }
    for (int i = 1; i <= 32; i++) {
      m_4p.add((random.nextDouble() * 10000).truncateToDouble() / 1000 + 5);
      f_4p.add((random.nextDouble() * 10000).truncateToDouble() / 1000 + 5);
      m_2p.add((random.nextDouble() * 10000).truncateToDouble() / 1000 + 5);
      f_2p.add((random.nextDouble() * 10000).truncateToDouble() / 1000 + 5);
    }
    MeasurementCollected measure = MeasurementCollected(
      id: -1,
      apparent_glucose: null,
      spo2: random.nextInt(5) + 96,
      pr_rpm: random.nextInt(30) + 60,
      temperature: (((random.nextInt(38) + 35) + random.nextDouble()) * 100)
              .truncateToDouble() /
          100,
      humidity: (random.nextDouble() * 10000).truncateToDouble() / 1000 + 10,
      m_4p: m_4p,
      f_4p: f_4p,
      m_2p: m_2p,
      f_2p: f_2p,
      maxled: maxled,
      minled: minled,
      date: DateTime.now(),
    );
    // await Future.delayed(Duration(seconds: random.nextInt(2) + 3));
    return measure;
  }

  /// Faz a leitura dos dados da medição do dispositivo conectado
  Future<MeasurementCollected> collect() async {
    // ##### ON CONNECTION LOST CORTAR COLETA
    assert(_connectedDevice != null);

    try {
      await _connectedDevice!.transmitter.write(
          utf8.encode(_BluetoothFlags.requesting),
          withoutResponse: true);
    } catch (e) {
      log.e('--- Collect :: BLE Write error');
    }

    late MeasurementCollected measure;
    List<double> m_4p = [];
    List<double> f_4p = [];
    List<double> m_2p = [];
    List<double> f_2p = [];
    Completer<void> confirm = Completer();

    valuesError = [];

    // prepara buffer e tx
    List<String> readBuffer = [];
    await _connectedDevice!.receiver.setNotifyValue(true);
    Stream<List<int>> readStream = _connectedDevice!.receiver.lastValueStream;
    // escuta novos valores do rx
    StreamSubscription<List<int>> streamSubs = readStream.listen((hex) {
      String dec = utf8.decode(hex);
      readBuffer.add(dec);
      valuesError.add(dec);
      if (dec.contains('\$')) {
        try {
          confirm.complete();
        } catch (e) {
          log.e('--- Collect :: Complete error');
        }
      }
    });
    // cancela subscrição se ocorrer timeout
    await confirm.future.timeout(const Duration(seconds: 20));
    await streamSubs.cancel();
    await _connectedDevice!.receiver.setNotifyValue(false);

    // split dos valores e conversão para num
    List<String> valuesStr = [];
    List<num> values = [];
    valuesStr.addAll(readBuffer.join().split(';'));
    for (String str in valuesStr) {
      try {
        values.add(num.parse(str));
      } catch (e) {
        log.e('--- Collect :: Value parse error');
      }
    }
    try {
      for (int d = 0; d < 128; d += 32) {
        for (int i = 0; i < 16; i += 2) {
          m_4p.add(values[d + i].toDouble());
          f_4p.add(values[d + i + 1].toDouble());
          m_2p.add(values[16 + d + i].toDouble());
          f_2p.add(values[16 + d + i + 1].toDouble());
        }
      }
      measure = MeasurementCollected(
        id: -1,
        apparent_glucose: null,
        pr_rpm: values[136].toInt(),
        spo2: values[137].toInt(),
        humidity: values[138].toDouble(),
        temperature: values[139].toDouble(),
        m_4p: m_4p,
        f_4p: f_4p,
        m_2p: m_2p,
        f_2p: f_2p,
        maxled: values.sublist(128, 132).cast<double>(),
        minled: values.sublist(132, 136).cast<double>(),
        date: DateTime.now(),
      );
    } catch (e) {
      log.e('--- Collect ::  List parse error $e');
    }

    // ### se ocorrer um erro precisa enviar que deu erro?
    // _flag = _BluetoothFlags.received;
    // _connectedDevice!.transmitter.write(utf8.encode(_BluetoothFlags.received));

    return measure;
  }
}

class _DeviceInternal {
  late final BluetoothDevice device;
  late final BluetoothCharacteristic receiver;
  late final BluetoothCharacteristic transmitter;
  _DeviceInternal({
    required this.device,
    required this.receiver,
    required this.transmitter,
  });
}

abstract class _BluetoothFlags {
  static const String requesting = 'SEND';
  // static const String received = 'RCVD';
}
