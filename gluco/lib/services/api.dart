// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart';
import 'package:gluco/db/database_helper.dart';
import 'package:gluco/models/measurement.dart';
import 'package:gluco/models/requests.dart';
import 'package:gluco/models/user.dart';
import 'package:gluco/models/patient.dart';
import 'package:gluco/services/custom_log.dart';

/// API para comunicação com o servidor
class API {
  API._privateConstructor();

  static final API instance = API._privateConstructor();

  static User? _user;
  User? get currentUser => _user;

  static bool _isDoctor = false;
  bool get isDoctor => _isDoctor;

  String? _token;
  String? _refresh_token;
  String? _client_id;

  final List<Patient> patientList = [];

  // TODO: Verificar problema de conexão no iOS
  // Detecção de conexão à internet
  final Connectivity _connectivity = Connectivity();
  Stream<ConnectivityResult> get connection =>
      _connection().asBroadcastStream();
  Stream<ConnectivityResult> _connection() async* {
    var result = await _connectivity.checkConnectivity();
    yield result;
    await for (final value in _connectivity.onConnectivityChanged) {
      yield value;
    }
  }

  Future<bool> hasConnection() async {
    ConnectivityResult result = await connection.first;
    return [
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.ethernet,
      ConnectivityResult.vpn
    ].contains(result);
  }

  /// Recupera mensagens de erro/confirmação recebida pelas requisições
  String? _responseMessage;
  String get responseMessage {
    String message = _responseMessage ?? '';
    // _responseMessage = null;
    return message;
  }

  final Client _client = Client();
  final String _authority = 'api.egluco.bio.br';

  /// Requisição para solicitação de novo token quando este expira,
  /// utilizando o refresh token, quando ambos expiram é necessário logar novamente
  Future<bool> _refreshToken() async {
    Uri url = Uri.https(_authority, '/refresh_token');

    Response response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $_refresh_token',
      },
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      TokenResponseModel responseModel =
          TokenResponseModel.fromMap(responseBody);
      _token = responseModel.token;
      _refresh_token = responseModel.refresh_token;
      _responseMessage = APIResponseMessages.success;
      log.i('--- Refresh token');
      return true;
    } else {
      _responseMessage = responseBody['detail'];
      log.w(
          '--- Refresh token :: ${response.reasonPhrase} :: $_responseMessage');
    }
    // TODO: Lançar exceção para logout?
    return false;
  }

  // Método que encapsula as funcionalidades de autenticação e recuperação de
  // perfil dos bds, tratando status de conectividade
  Future<bool> login([String? email, String? password]) async {
    assert(!((email == null) ^ (password == null)));
    bool auto = email == null || password == null;

    _user = User();

    if (await hasConnection()) {
      // TODO: Precisa dar timeout
      bool logged =
          auto ? await _fetchDBCredentials() : await _login(email, password);
      if (logged) {
        await _fetchUserInfo();
        // TODO: talvez esse login vai ficar muito demorado
        if (_user!.type == 'doctor') {
          _isDoctor = true;
          await _fetchPatients();
        }
        if (await _fetchUserProfile()) {
          // temporario
          await _updateProfilePic();
          //
          await updateDBUserProfile();
        }
        await DatabaseHelper.instance
            .insertCredentials(_client_id!, _refresh_token!);
        // TODO: Verificação se banco possui medições não enviadas
        return true;
      }
    } else {
      if (auto &&
          await _fetchDBCredentials(false) &&
          await _fetchDBUserProfile()) {
        // TODO: apiresponsemessage de modo offline
        log.i('--- Login :: not connected, offline mode');
        _responseMessage = APIResponseMessages.offlineMode;
        return true;
      }
      // TODO: apiresponsemessage sem conexão
      _responseMessage = APIResponseMessages.noConnection;
      log.i('--- Login :: not connected, no profile');
    }

    return false;
  }

  /// Busca por credenciais no banco local (autenticação automática),
  /// se houver realiza a atualização do token
  Future<bool> _fetchDBCredentials([bool refresh = true]) async {
    Map<String, String>? credentials =
        await DatabaseHelper.instance.queryCredentials();
    if (credentials == null) {
      return false;
    }
    _client_id = credentials['clientid'];
    _refresh_token = credentials['refreshtoken'];
    if (refresh) {
      if (!await _refreshToken()) {
        _client_id = null;
        _refresh_token = null;
        return false;
      }
    }
    return true;
  }

  /// Requisição para autenticação do usuário
  Future<bool> _login(String email, String password) async {
    Uri url = Uri.https(_authority, '/login');

    LoginRequestModel model =
        LoginRequestModel(email: email, password: password);

    Response response = await _client.post(
      url,
      headers: {
        'Content-type': 'application/json',
      },
      body: jsonEncode(model.toMap()),
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      LoginResponseModel responseModel =
          LoginResponseModel.fromMap(responseBody);
      _client_id = responseModel.client_id;
      _token = responseModel.token;
      _refresh_token = responseModel.refresh_token;
      _responseMessage = APIResponseMessages.success;
      log.i('--- Login :: $_responseMessage');
      return true;
    } else {
      try {
        _responseMessage = responseBody['detail'];
      } catch (e) {
        _responseMessage = responseBody['detail'][0]['msg'];
      }
      log.w('--- Login :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return false;
  }

  /// Encerra a sessão do usuário no aplicativo excluindo as credenciais
  /// do banco e setando variaveis como null
  Future<bool> logout() async {
    String client_id = _client_id!;
    _user = null;
    _client_id = null;
    _isDoctor = false;
    patientList.clear();
    _token = null;
    _refresh_token = null;
    log.i('--- Logout');
    return await DatabaseHelper.instance.deleteCredentials(client_id);
  }

  /// Requisição de cadastro de usuário
  Future<bool> signUp(String name, String email, String password) async {
    Uri url = Uri.https(_authority, '/signup/user');

    SignUpRequestModel model =
        SignUpRequestModel(name: name, email: email, password: password);

    Response response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(model.toMap()),
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      _responseMessage = responseBody['status'];
      log.i('--- Signup $_responseMessage');
      return true;
    } else {
      _responseMessage = responseBody['detail'];
      log.w('--- Signup :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return false;
  }

  // TODO: implementar recuperacao de senha
  // Future<bool> changePassword(){
  //   Uri url = Uri.https(_authority, '/change_password/${client_id!}');
  // }

  Future<bool> createUserProfile(
    DateTime birthday,
    double weight,
    double height,
    String sex,
    String diabetes_type,
    String profile_pic,
  ) async {
    assert(sex == 'M' || sex == 'F');
    assert(diabetes_type == 'T1' ||
        diabetes_type == 'T2' ||
        diabetes_type == 'NP');

    Uri url = Uri.https(_authority, '/user/${_client_id!}/create_profile');

    Profile profile = Profile(
      birthday: birthday,
      weight: weight,
      height: height,
      sex: sex,
      diabetes_type: diabetes_type,
      profile_pic: profile_pic,
    );

    Response response = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profile.toMap()),
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      _responseMessage = responseBody['status'];
      _user!.profile = profile;
      log.i('--- Create profile :: $_responseMessage');
      return true;
    } else {
      _responseMessage = responseBody['detail'];
      log.w(
          '--- Create profile :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return false;
  }

  // Requisição para alterar perfil do usuário (apenas peso e altura por enquanto)
  Future<bool> updateUserProfile(
    DateTime birthday,
    double weight,
    double height,
    String sex,
    String diabetes_type,
    String profile_pic,
  ) async {
    assert(sex == 'M' || sex == 'F');
    assert(diabetes_type == 'T1' ||
        diabetes_type == 'T2' ||
        diabetes_type == 'NP');

    Uri url = Uri.https(_authority, '/user/${_client_id!}/update_profile');

    Profile profile = Profile(
      birthday: birthday,
      weight: weight,
      height: height,
      sex: sex,
      diabetes_type: diabetes_type,
      profile_pic: profile_pic,
    );

    Response response = await _client.patch(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profile.toMap()),
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      _responseMessage = responseBody['status'];
      _user!.profile = profile;
      log.i('--- Update profile :: $_responseMessage');
      return true;
    } else {
      _responseMessage = responseBody['detail'];
      log.w(
          '--- Update profile :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return false;
  }

  // Requisição para recuperar nome e email do usuário
  Future<bool> _fetchUserInfo() async {
    Uri url = Uri.https(_authority, '/user/${_client_id!}/info');

    Response response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      _user!.name = responseBody['name'];
      _user!.email = responseBody['email'];
      _user!.type = responseBody['type'];
      _responseMessage = APIResponseMessages.success;
      log.i('--- Fetch user info :: $_responseMessage');
      return true;
    } else {
      _responseMessage = responseBody['detail'];
      log.w(
          '--- Fetch user info :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return false;
  }

  /// Requisição para recuperar perfil do usuário
  Future<bool> _fetchUserProfile() async {
    Uri url = Uri.https(_authority, '/user/${_client_id!}/profile');

    Response response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      _user!.profile = Profile.fromMap(responseBody);
      _responseMessage = APIResponseMessages.success;
      log.i('--- Fetch profile :: $_responseMessage');
      return true;
    } else {
      _responseMessage = responseBody['detail'];
      log.w(
          '--- Fetch profile :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return false;
  }

  @Deprecated('Usado temporariamente enquanto a api não salva imagem de perfil')
  Future<void> _updateProfilePic() async {
    User? userData =
        await DatabaseHelper.instance.queryUserByClientID(_client_id!);
    if (userData != null) {
      _user!.profile.profile_pic = userData.profile.profile_pic;
    }
  }

  // era pra ser um método privado, mas por causa da foto de perfil tá temporariamente publico
  Future<bool> updateDBUserProfile() async {
    User? userData =
        await DatabaseHelper.instance.queryUserByClientID(_client_id!);
    if (userData == null) {
      await DatabaseHelper.instance.insertUser(_user!, _client_id!);
      // não é a maneira mais inteligente mas é o que tem,
      // dava pra fazer pelo banco mas eu não quis por questões de encapsulamento
      User? userID =
          await DatabaseHelper.instance.queryUserByClientID(_client_id!);
      _user!.id = userID!.id;
      return true;
    } else {
      _user!.id = userData.id;
      return await DatabaseHelper.instance.updateUser(_user!);
    }
  }

  Future<bool> _fetchDBUserProfile() async {
    User? userData =
        await DatabaseHelper.instance.queryUserByClientID(_client_id!);
    _user!.id = userData!.id;
    _user!.name = userData.name;
    _user!.email = userData.email;
    _user!.profile = userData.profile;
    return true;
  }

  Future<List<Patient>> _fetchPatients() async {
    Uri url = Uri.https(_authority, '/doctor/${_client_id!}/binds_patient');

    List<Patient> pList = <Patient>[];

    Response response = await get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      for (dynamic patient in list) {
        pList.add(Patient.fromMap(patient));
      }
    } else {
      String detail = '';
      try {
        Map<String, dynamic> responseBody =
            jsonDecode(utf8.decode(response.bodyBytes));
        detail = responseBody['detail'];
      } catch (_) {}
      _responseMessage = detail;
      log.w('--- Patients :: ${response.reasonPhrase} :: $_responseMessage');
    }

    pList.sort((f, s) => f.serviceNumber.compareTo(s.serviceNumber));
    patientList.clear();
    patientList.addAll(pList);

    return pList;
  }

  /// Envia a medição coletada pelo bluetooth para ser processada na nuvem
  Future<bool> postMeasurements(MeasurementCollected measurement,
      [String? clientId]) async {
    clientId ??= _client_id;

    Uri url = Uri.https(_authority, '/measure/$clientId/create');

    Response response = await _client.post(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(measurement.toMap()),
    );

    Map<String, dynamic> responseBody =
        jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      _responseMessage = responseBody['status'];
      log.i('--- Measure :: $_responseMessage');
      return true;
    } else {
      _responseMessage = responseBody['detail'];
      log.w('--- Measure :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return false;
  }

  /// Busca tantas medições do banco remoto
  Future<List<MeasurementCompleted>> fetchMeasurements({
    String? clientId,
    int? amount,
    int? offset,
    int? daysBefore,
  }) async {
    clientId ??= _client_id;

    Map<String, dynamic> queryParams = {};
    if (amount != null) {
      queryParams['amount'] = amount.toString();
    }
    if (offset != null) {
      queryParams['offset'] = offset.toString();
    }
    if (daysBefore != null) {
      queryParams['days_before'] = daysBefore.toString();
    }
    Uri url = Uri.https(_authority, '/measure/$clientId/get', queryParams);

    List<MeasurementCompleted> measurementsList = <MeasurementCompleted>[];

    Response response = await get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      for (dynamic measure in list) {
        measurementsList.add(MeasurementCompleted.fromMap(measure));
      }
    } else {
      String detail = '';
      try {
        Map<String, dynamic> responseBody =
            jsonDecode(utf8.decode(response.bodyBytes));
        detail = responseBody['detail'];
      } catch (_) {}
      _responseMessage = detail;
      log.w(
          '--- Measure Fetch :: ${response.reasonPhrase} :: $_responseMessage');
    }

    return measurementsList;
  }
}

/// Classe abstrata com as possíveis mensagens retornadas pelas requisições,
/// pra facilitar na tomada de decisão quando erros ocorrem e caso as mensagens
/// sejam trocadas elas estão agrupadas aqui
abstract class APIResponseMessages {
  static const String success = 'Success';
  static const String alreadyRegistered = 'Email already exists...';
  static const String notRegistered = 'Invalid username';
  static const String emptyProfile = 'Non-existent User Profile!';
  static const String clientIdError = 'Non-existent User!';
  static const String wrongPassword = 'Invalid password';
  static const String tokenExpired = 'Token expired';
  static const String invalidFields = 'value is not a valid email address';
  static const String noConnection = 'no internet connection established';
  static const String offlineMode = 'no internet connection, limited features';
}
