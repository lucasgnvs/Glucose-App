/// Resposta da requisição de novo token
class TokenResponseModel {
  late final String token;
  late final String refresh_token;

  TokenResponseModel({
    required this.token,
    required this.refresh_token,
  });

  TokenResponseModel.fromMap(Map<String, dynamic> json) {
    token = json['access_token'];
    refresh_token = json['refresh_token'];
  }

  Map<String, dynamic> toMap() {
    final _data = <String, dynamic>{};
    _data['access_token'] = token;
    _data['refresh_token'] = refresh_token;
    return _data;
  }
}

/// Model para body da requisição de login
class LoginRequestModel {
  late final String email;
  late final String password;

  LoginRequestModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    final _data = <String, dynamic>{};
    _data['username'] = email;
    _data['password'] = password;
    return _data;
  }
}

/// Model para resposta de requisição de login
class LoginResponseModel {
  late final String client_id;
  late final String token;
  late final String refresh_token;

  LoginResponseModel({
    required this.client_id,
    required this.token,
    required this.refresh_token,
  });

  LoginResponseModel.fromMap(Map<String, dynamic> json) {
    client_id = json['client_id'];
    token = json['access_token'];
    refresh_token = json['refresh_token'];
  }
}

/// Model para body da requisição de cadastro
class SignUpRequestModel {
  late final String name;
  late final String email;
  late final String password;

  SignUpRequestModel({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    final _data = <String, String>{};
    _data['name'] = name;
    _data['email'] = email;
    _data['password'] = password;
    _data['confirm_password'] = password;
    return _data;
  }
}
