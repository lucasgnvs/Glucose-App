// ignore_for_file: prefer_final_fields, non_constant_identifier_names

import 'package:gluco/db/database_helper.dart';
import 'package:gluco/models/measurement.dart';
import 'package:gluco/services/api.dart';
import 'package:intl/intl.dart';

/// Classe de visualização das medições.
/// Possui os dados da medição propriamente ditos e o atributo isExpanded
/// para controlar o estado do painel expandido/colapsado na tela de histórico
class MeasurementView {
  late double glucose;
  late int spo2;
  late int pr_rpm;
  late DateTime date;
  bool isExpanded = false;

  MeasurementView(
    MeasurementCompleted measurement,
  ) {
    glucose = measurement.glucose;
    spo2 = measurement.spo2;
    pr_rpm = measurement.pr_rpm;
    date = measurement.date;
  }
}

/// Armazena as medições em memória em um mapa de meses para viabilizar a
/// construção da visualização do histórico de medições.
///
/// As chaves do mapa são strings 'mes, ano' e os valores são mapas de dias,
/// as chaves destes são strings 'diasemana, diames' e os valores são listas
/// de medições ordenadas da mais recente para a mais antiga
abstract class HistoryView {
  /// Mapa de medições
  static final Map<String, Map<String, List<MeasurementView>>>
      measurementsViewMap = <String, Map<String, List<MeasurementView>>>{};

  /// Medição mais recente, utilizada na visualização da home
  static final MeasurementCompleted currentMeasurement = MeasurementCompleted(
    id: -1,
    spo2: 0,
    pr_rpm: 0,
    glucose: 0,
    date: DateTime.now(), // talvez não faça sentido
  );

  /// Insere a medição atual no mapa
  static bool updateMeasurementsMap() {
    return _insertMeasurementView(currentMeasurement);
  }

  /// Mapeia Measurement para uma instância de MeasurementView
  /// e insere no mapa de visualização
  static bool _insertMeasurementView(MeasurementCompleted measurement) {
    if (measurement.id != -1) {
      // faz uma copia pq a inclusão é por referência
      MeasurementView _MeasurementView = MeasurementView(measurement);
      // TODO: Arrumar localização para seguir loc e não pt_BR
      String MMMMy = // 'mes, ano'
          DateFormat('MMMM, y', 'pt_BR').format(_MeasurementView.date);
      String EEEEd = // 'diasemana, diames'
          DateFormat('EEEE, d', 'pt_BR').format(_MeasurementView.date);
      // Capitalização dos nomes de mês e dia
      MMMMy = MMMMy.replaceRange(0, 1, MMMMy[0].toUpperCase());
      EEEEd = EEEEd.replaceRange(0, 1, EEEEd[0].toUpperCase());
      // Retira os '-feira'
      int index = EEEEd.indexOf('-');
      if (index != -1) {
        EEEEd = EEEEd.replaceRange(index, index + 6, '');
      }
      EEEEd = EEEEd.split('-')[0];
      // Insere a medição no mapa
      if (!measurementsViewMap.containsKey(MMMMy)) {
        measurementsViewMap[MMMMy] = {};
      }
      if (!measurementsViewMap[MMMMy]!.containsKey(EEEEd)) {
        measurementsViewMap[MMMMy]![EEEEd] = [];
      }
      // TODO: talvez verificar se não está incluindo duplicado, por consistência
      measurementsViewMap[MMMMy]![EEEEd]!.insert(0, _MeasurementView);
      return true;
    }
    return false;
  }

  /// Busca as medições recentes do usuário no banco e mapeia em memória,
  /// utilizada no login
  static Future<bool> fetchHistory() async {
    List measurementsList = await DatabaseHelper.instance
        .queryMeasurementCompleted(API.instance.currentUser!);

    if (measurementsList.isNotEmpty) {
      for (MeasurementCompleted measurement in measurementsList.reversed) {
        _insertMeasurementView(measurement);
      }
      currentMeasurement.id = measurementsList.first.id;
      currentMeasurement.glucose = measurementsList.first.glucose;
      currentMeasurement.spo2 = measurementsList.first.spo2;
      currentMeasurement.pr_rpm = measurementsList.first.pr_rpm;
      currentMeasurement.date = measurementsList.first.date;
      return true;
    }

    return false;
  }

  /// Apaga as medições da memória, utilizado no logout
  static void disposeHistory() {
    measurementsViewMap.clear();
    currentMeasurement.id = -1;
    currentMeasurement.glucose = 0;
    currentMeasurement.spo2 = 0;
    currentMeasurement.pr_rpm = 0;
    currentMeasurement.date = DateTime.now();
  }
}
