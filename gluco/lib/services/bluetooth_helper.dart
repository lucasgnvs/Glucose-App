import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fftea/fftea.dart';
import 'package:gluco/models/device.dart';
import 'package:gluco/models/exceptions/bluetooth_exceptions.dart';
import 'package:gluco/models/utils/complex_number.dart';
import 'package:gluco/models/measurement.dart';
import 'package:gluco/services/custom_log.dart';

class BluetoothHelper {
  BluetoothHelper._privateConstructor();

  static final BluetoothHelper instance = BluetoothHelper._privateConstructor();

  // Dispositivo atualmente conectado, é o que é efetivamente utilizado na coleta
  _DeviceInternal? _connectedDevice;

  /// Stream com sinais de alteração no estado do Bluetooth ligado/desligado
  Stream<bool> get state => _state().asBroadcastStream();

  /// Stream que encapsula e transmite os sinais de estado do FlutterBlue
  Stream<bool> _state() async* {
    await for (final value in FlutterBluePlus.adapterState) {
      if (value == BluetoothAdapterState.turningOff) {
        disconnect();
        _devices.clear();
        _resultsSubs?.cancel();
        _resultsSubs = null;
      }
      yield value == BluetoothAdapterState.on;
    }
  }

  /// Stream com sinais de iniciando/parando escaneamento
  Stream<bool> get scanning => _scanning().asBroadcastStream();

  /// Subscrição da stream com resultados de escaneamento, para impedir duplicatas
  /// e permitir o posterior cancelamento
  StreamSubscription<List<ScanResult>>? _resultsSubs;

  /// Stream que encapsula e transmite os sinais de escaneamento do FlutterBlue
  Stream<bool> _scanning() async* {
    await for (final value in FlutterBluePlus.isScanning) {
      yield value;
    }
  }

  /// Stream com sinais de conectado/desconectado do dispositivo atualmente conectado
  Stream<bool> get connected => _connected.stream;
  final StreamController<bool> _connected = StreamController<bool>.broadcast();

  /// Stream com sinais do FlutterBlue de conexão do dispositivo
  StreamSubscription<BluetoothConnectionState>? _connSubs;

  /// Nome utilizado para filtro dos dispositivos
  static const String _deviceName = 'EGLUCO';

  static const String _serviceUUID = '6E400001';
  static const String _txUUID = '6E400002';
  static const String _rxUUID = '6E400003';
  static const String _collectFlag = '@atualizacao';

  /// Tempo de timeout para escaneamento (5s)
  static const Duration _timeoutScan = Duration(seconds: 5);

  /// Tempo de timeout para conexão com dispositivo (10s)
  static const Duration _timeoutConn = Duration(seconds: 10);

  /// Tempo de timeout para leitura da medição (25s)
  static const Duration _timeoutRead = Duration(seconds: 25);

  /// Lista de dispositivos encontrados pelo escaneamento
  final List<BluetoothDevice> _devices = [];

  /// Valor da bateria
  double _valueVBat = -1;
  double get battery => _valueVBat;

  /// Mapeamento dos BluetoothDevices para Devices com inclusão do
  /// dispositivo atualmente conectado
  List<Device> get devices {
    List<Device> dvcs = _devices
        .map((d) =>
            // Device(id: d.remoteId.str, name: d.platformName))
            Device(id: d.remoteId.str, name: _formatDeviceName(d.remoteId.str)))
        .toList();
    if (_connectedDevice != null) {
      // encontra o dispositivo conectado e marca como conectado
      dvcs
          .firstWhere((d) => d.id == _connectedDevice!.device.remoteId.str)
          .connected = true;
    }
    return dvcs;
  }

  /// Inicia escaneamento e inclui os resultados em [devices]
  Future<void> scan() async {
    // adiciona a função de listen somente se a subscrição ainda não tiver sido feita
    _resultsSubs ??= FlutterBluePlus.onScanResults.listen(
      (results) {
        for (ScanResult r in results) {
          _devices.add(r.device);
          log.i(
              '--- Scan device :: ${r.device.platformName} - ${r.device.remoteId.str}');
        }
      },
    );

    // limpa a lista dos últimos escaneados e inicia novamente
    _devices.clear();
    await FlutterBluePlus.startScan(
      withNames: [_deviceName],
      timeout: _timeoutScan,
    );

    // dispositivos conectados não são inseridos automaticamente na lista de scan do FlutterBlue
    if (_connectedDevice != null) {
      _devices.insert(0, _connectedDevice!.device);
    }
  }

  /// Tenta estabelecer conexão com um dispositivo, podendo falhar por timeout
  /// ou por não encontrar as características de RX e TX, se bem sucedido o
  /// dispositivo atual é atualizado e a transmissão da stream de conexão é setada
  Future<bool> connect(Device dvc) async {
    // tenta realizar conexão do app ao dispositivo selecionado
    BluetoothDevice device;
    try {
      device = _devices.firstWhere((d) => d.remoteId.str == dvc.id);
      await device.connect(timeout: _timeoutConn, mtu: 512);
    } catch (e) {
      log.w('--- Connecting status :: Could not connect : Exception: $e');
      return false;
    }

    // busca das características com UUIDs de RX e TX
    List<BluetoothCharacteristic> characteristics;
    BluetoothCharacteristic rx;
    BluetoothCharacteristic tx;
    try {
      List<BluetoothService> services = await device.discoverServices();
      characteristics = services
          .firstWhere((element) =>
              element.uuid.str.toUpperCase().contains(_serviceUUID))
          .characteristics;
      rx = characteristics.firstWhere(
          (element) => element.uuid.str.toUpperCase().contains(_rxUUID));
      tx = characteristics.firstWhere(
          (element) => element.uuid.str.toUpperCase().contains(_txUUID));
    } catch (e) {
      log.w(
          '--- Connecting status :: Characteristics not found : Exception: $e');
      await device.disconnect(queue: false);
      return false;
    }

    // estabelece novo dispositivo conectado, inicia a stream de conexão,
    // e inicia transmissão do sinal que solicita medição
    _connectedDevice = _DeviceInternal(
      device: device,
      receiver: rx,
      transmitter: tx,
    );
    await _saveDevice(device.remoteId.str);

    _connected.add(true);
    _connSubs ??= device.connectionState.listen(
      (state) async {
        if (state != BluetoothConnectionState.connected) {
          // TODO: botar o _connected.add(conn) aqui???
          if (_connectedDevice == null) {
            // ao desconectar, cancela a stream de estado
            _connSubs?.cancel();
            _connSubs = null;
            _connected.add(false);
            log.i('--- Connection status :: Disconnected manually');
          } else {
            try {
              // tenta reconectar
              await Future.delayed(const Duration(milliseconds: 500)); // 133
              throw 'reconnect erro 133'; // TODO: resolver esse erro 133
              // -----------------------------------------
              // await _connectedDevice!.device.connect(timeout: _timeoutConn);
              // _connected.add(true);
              // -----------------------------------------
              log.i('--- Connection status :: Reconnected');
            } catch (e) {
              // timeout da reconexão
              _connected.add(false);
              disconnect();
              // TODO: corrigir para não chamar manually após signal loss
              log.w('--- Connection status :: Disconnected by signal loss');
            }
          }
        }
      },
    );

    log.i('--- Connecting status :: Success');
    return true;
  }

  /// Encapsula a função de desconectar do FlutterBlue e gerencia o dispositivo
  /// atualmente conectado
  Future<bool> disconnect() async {
    // NOTE: é a única função que seta _connectedDevice como null
    try {
      if (_connectedDevice != null) {
        BluetoothDevice dvc = _connectedDevice!.device;
        _connectedDevice = null;
        _valueVBat = -1;
        await dvc.disconnect();
      }
      return true;
    } catch (e) {
      log.w('--- Disconnecting status :: Exception: $e');
      return false;
    }
  }

  /// Busca por um dispositivo previamente conectado no SharedPreferences
  /// para tentar reconectar ao iniciar o aplicativo
  Future<bool> autoConnect() async {
    // TODO: como reconectar automaticamente após longo período desconectado com app aberto?
    // ----------------------------------------- TODO: rever auto connect
    // String? deviceId = await _fetchDevice();
    // if (deviceId == null) {
    //   return false;
    // }
    // log.i('--- AutoConnect SP :: $deviceId');
    // await scan();
    // await Future.delayed(
    //     _timeoutScan); // NOTE: scan() retorna imediatamente, é necessário esperar completar
    // return await connect(Device(id: deviceId));
    // -----------------------------------------
    return false;
  }

  /// Faz a leitura dos dados da medição do dispositivo conectado
  Future<MeasurementCollected> collect() async {
    // TODO: Cortar coleta se a conexão for perdida
    assert(_connectedDevice != null);
    log.i('--- Collect :: New measurement started');

    // chaves de identificação dos dados de leitura
    const String keyVBIA1 = 'V_bia1';
    const String keyVBIA2 = 'V_bia2';
    const String keyLED = 'Led_foto';
    const String keyPlest = 'Plest';
    const String keyVBAT = 'V_bat';
    String currKey = '';

    // buffers para leitura
    final List<String> bufferVBIA1 = [];
    final List<String> bufferVBIA2 = [];
    final List<String> bufferLED = [];
    final List<String> bufferPlest = [];
    final List<String> bufferVBAT = [];

    // dados para preenchimento após parse
    late MeasurementCollected measure;
    Completer<bool> confirm = Completer();

    // subscreve na caraterística de leitura e escreve para nova medição
    await _connectedDevice!.receiver.setNotifyValue(true);
    try {
      await _connectedDevice!.transmitter.write(utf8.encode(_collectFlag));
    } catch (e) {
      log.e('--- Collect :: BTLE Write error');
      throw WritingTimeoutBluetoothException();
    }

    // escuta subscrição para chegada de novos valores e preenche os buffers
    StreamSubscription<List<int>> streamSubs =
        _connectedDevice!.receiver.onValueReceived.listen((hex) {
      String dec = utf8.decode(hex);
      if (dec.contains(keyVBIA1)) {
        currKey = keyVBIA1;
      }
      if (dec.contains(keyVBIA2)) {
        currKey = keyVBIA2;
      }
      if (dec.contains(keyLED)) {
        currKey = '';
        bufferLED.add(dec);
        return;
      }
      if (dec.contains(keyPlest)) {
        currKey = '';
        bufferPlest.add(dec);
        return;
      }
      if (dec.contains(keyVBAT)) {
        currKey = '';
        bufferVBAT.add(dec);
        try {
          confirm.complete(true);
        } catch (e) {
          log.e('--- Collect :: Complete error');
        }
        return;
      }
      // dividido com currKey por causa dos tamanhos dos chunks
      if (currKey == keyVBIA1) {
        bufferVBIA1.add(dec);
      }
      if (currKey == keyVBIA2) {
        bufferVBIA2.add(dec);
      }
    });

    // cancela subscrição e retorna se ocorrer timeout
    bool completed =
        await confirm.future.timeout(_timeoutRead, onTimeout: (() => false));
    await streamSubs.cancel();
    await _connectedDevice!.receiver.setNotifyValue(false);
    if (!completed) {
      log.e('--- Collect :: Timed out while receiving data');
      throw ReadingTimeoutBluetoothException();
    }

    // split dos valores e conversão para num
    List<double> valuesVBIA1 = _parseChunks(bufferVBIA1);
    List<double> valuesVBIA2 = _parseChunks(bufferVBIA2);
    List<double> valuesLED = _parseChunks(bufferLED);
    List<double> valuesPlest = _parseChunks(bufferPlest);

    // atualizando bateria
    double valueVBAT =
        _parseChunks(bufferVBAT).map((e) => _applyConversion(e)).first;
    _valueVBat = (valueVBAT / 9.0).clamp(0.0, 1.0);

    // último valor é 100000, não faz parte
    valuesVBIA1.removeLast();
    valuesVBIA2.removeLast();

    log.i(
        '--- Collect :: Measure received : ${valuesVBIA1.length} - ${valuesVBIA2.length} - ${valuesLED.length} - ${valuesPlest.length} - $_valueVBat');

    final List<ComplexNumber> convBIA1 = [];
    final List<ComplexNumber> convBIA2 = [];

    try {
      // calcula fft dos valores de tensão recebidos
      List<ComplexNumber> freqVBIA1 = _calcVoltageFFT(valuesVBIA1);
      List<ComplexNumber> freqVBIA2 = _calcVoltageFFT(valuesVBIA2);

      // calcula bioimpedancia pelos valores de tensão recebidos e corrente fixa
      List<ComplexNumber> bia1 = _calcBIA(freqVBIA1, _freqIBIA1);
      List<ComplexNumber> bia2 = _calcBIA(freqVBIA2, _freqIBIA2);

      // realiza conversão do dibs
      convBIA1.addAll(_convertList(bia1));
      convBIA2.addAll(_convertList(bia2));

      log.i(
          '--- Collect :: Converted BIA : ${convBIA1.length} - ${convBIA2.length}');
    } catch (e) {
      log.e('--- Collect :: FFT Exception : $e');
      throw ConvertingErrorBluetoothException();
    }

    try {
      List<double> m_4p = [];
      List<double> f_4p = [];
      for (ComplexNumber n in convBIA1) {
        m_4p.add(n.real);
        f_4p.add(n.imag);
      }
      for (ComplexNumber n in convBIA2) {
        m_4p.add(n.real);
        f_4p.add(n.imag);
      }
      measure = MeasurementCollected(
        id: -1,
        apparent_glucose: null,
        pr_rpm: valuesPlest[0].round(),
        spo2: valuesPlest[1].round(),
        humidity: 0, // removido
        temperature: 0, // removido porém pode retornar
        m_4p: m_4p, // primeiros 16 [0 a 100kHz] e segundos 16 [0 a 400kHz]
        f_4p: f_4p,
        m_2p: List.filled(32, 0), // removido
        f_2p: List.filled(32, 0), // removido
        maxled: valuesLED, // [desligado, vermelho, infra1, infra2]
        minled: List.filled(4, 0),
        date: DateTime.now(),
      );
    } catch (e) {
      log.e('--- Collect :: Error composing measure : $e');
      throw ComposingErrorBluetoothException();
    }

    log.i('--- Collect :: Completed succesfully');
    return measure;
  }

  /// Retorna nome do dispositivo no formato 'eGluco {útlimos 4 digitos MAC}'
  String _formatDeviceName(String id) {
    return 'eGluco ${id.replaceAll(RegExp(':'), '').substring(8)}';
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

  List<double> _parseChunks(List<String> buffer) {
    List<double> values = [];
    try {
      String joined = buffer.join();
      int st = joined.indexOf('{');
      int ed = joined.indexOf('}');
      String subs = joined.substring(st + 1, ed);
      values = subs.split(',').map<double>((s) => double.parse(s)).toList();
    } catch (e) {
      log.e('--- Collect :: Value parse error : $e');
    }
    return values;
  }

  final List<int> _freqIdx = [
    0,
    32,
    64,
    96,
    128,
    160,
    192,
    224,
    256,
    288,
    320,
    352,
    384,
    416,
    448,
    480
  ];
  final List<ComplexNumber> _freqIBIA1 = [];
  final List<ComplexNumber> _freqIBIA2 = [];

  void _calcCurrentFFT() {
    _freqIBIA1.clear();
    _freqIBIA2.clear();

    FFT fft = FFT(512);

    List<double> frag1 = [0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1];
    List<double> frag2 = [0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0];

    List<double> dibs1 = List.generate(512, (i) => frag1[i % 16]);
    List<double> dibs2 = List.generate(512, (i) => frag2[i % 16]);

    final freq1 = fft.realFft(dibs1);
    final freq2 = fft.realFft(dibs2);

    for (int idx in _freqIdx) {
      _freqIBIA1.add(ComplexNumber(freq1[idx].x, freq1[idx].y));
      _freqIBIA2.add(ComplexNumber(freq2[idx].x, freq2[idx].y));
    }
  }

  List<ComplexNumber> _calcVoltageFFT(List<double> vbia) {
    final FFT fft = FFT(512);
    final freq = fft.realFft(vbia);

    final List<ComplexNumber> freqVBIA = [];

    for (int idx in _freqIdx) {
      freqVBIA.add(ComplexNumber(freq[idx].x, freq[idx].y));
    }
    return freqVBIA;
  }

  List<ComplexNumber> _calcBIA(
    List<ComplexNumber> vbia,
    List<ComplexNumber> ibia,
  ) {
    if (ibia.isEmpty) {
      _calcCurrentFFT();
    }
    final List<ComplexNumber> bia = [];
    for (int i = 0; i < vbia.length; i++) {
      bia.add(vbia[i].div(ibia[i]));
    }
    return bia;
  }

  double _applyConversion(double n) {
    return 1.000 / 4096.0 * n;
    // return 1.000 / (4096.0 * 500e-6) * n;
  }

  List<ComplexNumber> _convertList(List<ComplexNumber> list) {
    final List<ComplexNumber> out = [];
    for (ComplexNumber n in list) {
      out.add(
        ComplexNumber(
          _applyConversion(n.real),
          _applyConversion(n.imag),
        ),
      );
    }
    return out;
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
